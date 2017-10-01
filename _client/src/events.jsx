import React from "react";
import { render } from "react-dom";

function format_date(date) {
    const months = [
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December",
    ];
    const days = [
        "Sunday",
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday",
        "Saturday",
    ];
    let day_of_week = days[date.getDay()];
    let month = months[date.getMonth()];
    let day = date.getDate();
    let year = date.getFullYear();
    return `${day_of_week}, ${day} ${month} ${year}`;
}

function format_time (time) {
    function pad(n) {
        if (n < 10) {
            return `0${n}`;
        } else {
            return n;
        }
    }

    return pad(time.getHours()) + pad(time.getMinutes());
}

function format_datetime_object(obj) {
    if (obj.date) {
        return format_date(obj.date);
    } else if (obj.dateTime) {
        return `${format_time(obj.dateTime)} ${format_date(obj.dateTime)}`
    } else {
        return obj.toString();
    }
}

function format_event_time(start, end) {
    if (end) {
        return `${format_datetime_object(start)} - ${format_datetime_object(end)}`;
    } else {
        return format_datetime_object(start);
    }
}

class TopSection extends React.Component {

    _render_single_event(evt) {
        let event_time = format_event_time(evt.start, evt.end);
        let evt_summary = evt.summary;
        let evt_location;

        if (evt.location) {
            evt_location = evt.location + " |";
        } else {
            evt_location = ""
        }

        return <div key={evt.id} className="container col-8">
            <div className="jumbotron" style={{padding: "1rem 2rem"}}>
                <div className="row">
                    <div className="col-12 col-lg-2 col-xl-1">
                        <center><i className="fa fa-calendar fa-3x" aria-hidden="true"></i></center>
                    </div>
               	    <div className="col-12 text-center text-lg-left col-lg-10 col-xl-11">
               	        <h2>{ evt_summary }</h2>
               	        <p>{ evt_location } { event_time }</p>					
               	    </div>
                </div>
            </div>
        </div>
    }

    render () {
        return <div>
            {this.props.events.map((evt) => {
                return this._render_single_event(evt);
            })}
        </div>
    }
}

function maybe_parse_date (obj) {
    if (obj) {
        if (obj.date) {
            return Object.assign({}, obj, {date: new Date(obj.date)});
        } else if (obj.dateTime) {
            return Object.assign({}, obj, {dateTime: new Date(obj.dateTime)});
        }
    }

    return obj;
}

class App extends React.Component {

    constructor () {
        super();
        this.state = {events: null}
    }

    componentDidMount () {
        let cb = (() => {
            $.ajax("http://35.177.234.162:8102/").done(
                (response) => {
                    let events = response.map((evt) => {
                        return Object.assign({}, evt, {
                            created: new Date(evt.created),
                            start: maybe_parse_date(evt.start),
                            end: maybe_parse_date(evt.end),
                        });
                    });
                    this.setState({ events: events });
                });
        });
        cb();
        this._callback = setInterval(cb, 5000);
    }

    componentWillUnmount () {
    }

    render () {
        if (this.state.events === null) {
            return <div className="text-center">Loading ...</div>
        } else {
            return <div>
                <TopSection events={this.state.events} />
            </div>
        }
    }
}

var app = document.getElementById("app");
render(<App />, app);
