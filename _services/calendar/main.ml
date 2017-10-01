open Core
open Async

module Config = struct
  type t =
    { access_token  : string;
      refresh_token : string;
      client_id     : string;
      client_secret : string;
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

let command_run =
  let open Command.Let_syntax in
  Command.async' ~summary:"Run the service"
    [%map_open
     let config_file_path =
       flag "-config" (required file) ~doc:"PATH to config file"
     in
     let open Deferred.Let_syntax in
     fun () ->
       Deferred.return ()
    ]
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
