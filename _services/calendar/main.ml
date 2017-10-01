open Core
open Async
open Async_unix

module Config = struct
  type t =
    { access_token  : string;
      refresh_token : string;
      client_id     : string;
      client_secret : string;
      port          : int
    }
  [@@deriving sexp]

  let to_app t =
    let client_id = t.client_id in
    let client_secret = t.client_secret in
    Gapi_services.init_app ~client_secret ~client_id
  ;;
end

let command_auth =
  let open Command.Let_syntax in
  Command.async' ~summary:"Perform access token OAuth"
    [%map_open
      let config_file_path =
        flag "-config" (required file) ~doc:"PATH to config file"
      in
      fun () ->
        let open Deferred.Let_syntax in
        let%bind config =
          Reader.load_sexp_exn config_file_path Config.t_of_sexp
        in
        let (`Access_token access_token, `Refresh_token refresh_token) =
          Gapi_services.get_tokens (Config.to_app config)
        in
        let config = { config with access_token; refresh_token; } in
        Writer.save_sexp config_file_path ([%sexp_of: Config.t] config)
    ]
;;

type 'a req_handler =
  body:Cohttp_async.Body.t
  -> 'a
  -> Cohttp_async.Request.t
  -> Cohttp_async.Server.response Async.Deferred.t

let fetch_events (config : Config.t) =
  let { Config.client_id;
        client_secret;
        refresh_token;
        access_token;
        port = _ } =
    config
  in
  let app = Gapi_services.init_app ~client_id ~client_secret in
  let service = Gapi_services.init app ~access_token ~refresh_token in
  In_thread.run (fun () ->
      (* TODO(fyquah): I think there needs to be some kind of thread yielder
       * here. Can't remember what the exact function call is though.
       *)
      Gapi_services.get_events ~after:(Time.now ()) service)
;;

let run_server ~events_ref ~(config : Config.t) =
  let module Request = Cohttp_async.Request in
  let module Response = Cohttp_async.Response in
  let module Header = Cohttp.Header in
  let root_handler ~(body : Cohttp_async.Body.t) _sock
      (req : Cohttp_async.Request.t) =
    match Request.meth req with
    | `GET -> begin
        (*
      let uri = Request.uri req in
      let after =
        match Uri.get_query_param uri "after" with
        | Some t -> Time.of_string t
        | None -> Time.now ()
      in
           *)
      let headers = 
        let h = Cohttp.Header.init () in
        let h = Cohttp.Header.add h "Content-type" "application/json" in
        Cohttp.Header.add h "Access-Control-Allow-Origin" "*"
      in
      let json = 
        `List (
          List.map !events_ref ~f:(fun event ->
              Gapi_services.Event.to_data_model event
              |> GapiJson.data_model_to_json)
        )
      in
      Cohttp_async.Server.respond_string ~headers ~status:`OK 
        (Yojson.Safe.to_string json)
      end
    | _ -> failwith "Unknown method"
  in
  let handlers : (string * 'a req_handler) list =
    [("/", root_handler)]
  in
  Cohttp_async.Server.create ~on_handler_error:`Ignore
    (Tcp.on_port config.port)
    (fun ~body sock req ->
      let req_path = Uri.path (Request.uri req) in
      List.find_map_exn handlers ~f:(fun (path, handler) ->
          if String.equal path req_path 
          then Some (handler ~body sock req)
          else None))
  >>| fun (_ : (Async_extra.Import.Socket.Address.Inet.t, int) Cohttp_async.Server.t) ->
  printf "Server ready and listening at port %d" config.port
;;

let command_run =
  let open Command.Let_syntax in
  Command.async' ~summary:"Run the service"
    [%map_open
     let config_file_path =
       flag "-config" (required file) ~doc:"PATH to config file"
     in
     let open Deferred.Let_syntax in
     fun () ->
       let (events_ref : Gapi_services.Event.t list ref) = ref [] in
       let%bind config =
         Reader.load_sexp_exn config_file_path [%of_sexp: Config.t]
       in
       Async.Clock.every' ~start:Deferred.unit (Time.Span.of_min 1.) (fun () ->
           let%map events = fetch_events config in
           events_ref := events
         );
       let%bind _ = run_server ~events_ref ~config in
       Deferred.never ()]
;;

let command =
  Command.group ~summary:"ICRS API Server Services"
    [ ("authenticate", command_auth);
      ("run", command_run);
    ]
;;

let () =
  let open Command.Let_syntax in
  Command.run command
;;
