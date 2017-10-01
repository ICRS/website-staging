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
            <div className={ "jumbotron " + this.props.additional_class } style={{padding: "1rem 2rem"}}>
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
        return <section className={this.props.section_class}>
            <h2 className="section-heading text-center">
            { this.props.title }
            </h2>
            {(() => {
                if (this.props.children) {
                    return <div>
                        {this.props.children}
                    </div>
                } else {
                    return <br />
                }
            })()}
            {(() => {
                if (this.props.events === null) {
                    return <div className="container text-center"><div className={this.props.additional_class}>Loading ...</div></div>
                } else {
                    return this.props.events.map((evt) => {
                        return this._render_single_event(evt);
                    })
                }
            })()}
        </section>
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

function getStartDate(obj) {
    if (obj.start) {
        if (obj.start.date) {
            return obj.start.date.getTime();
        } else if (obj.start.dateTime) {
            return obj.start.dateTime.getTime();
        }
    }

    return 0;
}

class App extends React.Component {

    constructor () {
        super();
        this.state = {upcoming_events: null, past_events: null}
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
                    events = events.sort((a, b) => {
                        a = getStartDate(a);
                        b = getStartDate(b);

                        if (a < b) return -1;
                        else if (a > b) return 1;
                        else return 0;
                    });
                    let now = new Date();
                    let upcoming_events = events.filter((evt) => {
                        return getStartDate(evt) >= now.getTime();
                    });
                    let past_events = events.filter((evt) => {
                        return getStartDate(evt) < now.getTime();
                    });
                    past_events.reverse();
                    this.setState({
                        upcoming_events: upcoming_events,
                        past_events: past_events,
                    });
                });
        });
        cb();
    }

    componentWillUnmount () {
    }

    render () {
        let google_calendar_link = "https://calendar.google.com/calendar/embed?src=icrobotics.co.uk_7vpig3lkheki7njbq1taq1soqo%40group.calendar.google.com&ctz=Europe/London";

        return <div>
            <TopSection section_class="non-home-top bg-primary" events={this.state.upcoming_events} title="Upcoming events"
              additional_class="white-jumbotron">
                <br />
                <center>
                    <a target="_none" href={google_calendar_link} className="btn btn-default btn-xl sr-button">
                        Subscribe
                    </a>
                </center>
                <br />
            </TopSection>
            <TopSection events={this.state.past_events} title="Past Events" additional_class="magic-jumbotron" />
        </div>
    }
}

var app = document.getElementById("app");
render(<App />, app);
