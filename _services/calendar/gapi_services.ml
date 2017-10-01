open GapiUtils.Infix
open GapiCalendarV3Model
open GapiCalendarV3Service

module Event = GapiCalendarV3Model.Event
module Time = Core.Time

type app =
  { client_id     : string;
    client_secret : string;
  }

type t =
  { auth_context : GapiConversation.Session.auth_context;
    app          : app;
  }

let application_name = "icrs-website"
let icrs_calendar_id =
  "icrobotics.co.uk_7vpig3lkheki7njbq1taq1soqo@group.calendar.google.com"
;;

let init_app ~client_id ~client_secret = { client_id; client_secret; }

let gapi_config_of_app app : GapiConfig.t =
  let client_id = app.client_id in
  let client_secret = app.client_secret in
  let gapi_auth =
    GapiConfig.OAuth2
      { GapiConfig.
        client_id;
        client_secret;
        refresh_access_token = None
      }
  in
  { GapiConfig.default with
    GapiConfig.application_name = application_name;
    auth = gapi_auth
  }
;;

let get_tokens app =
  let gapi_config = gapi_config_of_app app in
  let on_connect session =
    let redirect_uri = "http://icrs.io/" in
    let { client_id; client_secret } = app in
    let authorization_code_url =
      let scope = [ GapiCalendarV3Service.Scope.calendar_readonly ] in
      GapiOAuth2.authorization_code_url ~redirect_uri ~scope
        ~response_type:"code" client_id
    in
    (* We cannot use Format.printf, as it is bound by async's scheduler
     * (and this function is not aware of Async at all!)
     *)
    print_endline "Point your browser to authorization_code_url";
    print_endline authorization_code_url;
    print_endline "Enter the authentication code:";
    let code = input_line stdin in
    let (response, _session) =
      GapiOAuth2.get_access_token session
        ~client_id ~client_secret ~code ~redirect_uri
    in
    match response with
    | GapiAuthResponse.OAuth2AccessToken token ->
      (`Access_token token.access_token,
       `Refresh_token token.refresh_token)
    | _ -> failwith "Not supported OAuth2 response"
  in
  GapiConversation.with_curl gapi_config on_connect
;;

let init app ~access_token ~refresh_token =
  let auth_context = 
    GapiConversation.Session.OAuth2
      { oauth2_token  = access_token;
        refresh_token = refresh_token;
      }
  in
  { app; auth_context }
;;

let get_events ?after (t : t) =
  let (_ : Time.t option) = after in
  let gapi_config = gapi_config_of_app t.app in
  let on_connect session =
    let get_events next_page_token session =
      print_endline "here";
      let (events, session) =
        EventsResource.list ~calendarId:icrs_calendar_id session
      in
      List.iter (fun (event : Event.t) ->
          Format.printf "%s\n" event.summary)
        events.items;
      ignore session;
      events.items
    in
    get_events None session
  in
  GapiConversation.with_curl ~auth_context:t.auth_context gapi_config
    on_connect
;;
