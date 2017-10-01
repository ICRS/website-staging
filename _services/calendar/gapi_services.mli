module Event = GapiCalendarV3Model.Event
module Time = Core.Time

type app
type t

val get_tokens
   : app
  -> ([ `Access_token of string ] * [ `Refresh_token of string ])

val init_app : client_id: string -> client_secret: string -> app

val init
   : app
  -> access_token: string
  -> refresh_token: string
  -> t

(* WARNING: This function is BLOCKING despite being IO-bound. Run
 *          this function in a separate thread (and not a [Deferred.t]),
 *          possibly using a thread yielder of some kind.
 *)
val get_events : ?after: Time.t -> t -> Event.t list
