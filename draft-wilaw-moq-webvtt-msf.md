---
title: "WebVTT Packaging for MOQT Streaming Format"
category: info
docname: draft-wilaw-moq-webvtt-msf-latest
submissiontype: IETF
number:
date:
consensus: true
v: 3
area: "Applications and Real-Time"
workgroup: "Media Over QUIC"
keyword:
 - MoQ
 - MSF
 - WebVTT
venue:
  group: "Media Over QUIC"
  type: "Working Group"
  mail: "moq@ietf.org"
  arch: "https://mailarchive.ietf.org/arch/browse/moq/"

author:
  -
    fullname: Will Law
    organization: Akamai
    email: wilaw@akamai.com
  -
    fullname: Suhas Nandakumar
    organization: Cisco
    email: snandaku@cisco.com

normative:
  MSF: I-D.draft-ietf-moq-msf
  JSON: RFC8259
  WEBVTT:
    title: "W3C, WebVTT: The Web Video Text Tracks Format"
    date: April 2019
    target: https://www.w3.org/TR/webvtt1/

--- abstract

This document specifies the JSON packaging format for delivering WebVTT
caption and subtitle content as event timeline tracks within the MOQT
Streaming Format (MSF).

--- middle

# Introduction

This document defines how WebVTT {{WEBVTT}} content is packaged for
delivery over MSF {{MSF}} event timelines using the `urn:msf:captions:webvtt`
event type.

WebVTT is a widely-used format for delivering captions and subtitles on the web.
MSF provides event timeline tracks ({{MSF, Section 11}}) as a mechanism for
delivering time-synchronized metadata alongside media content. This specification
bridges these two by defining a JSON-based packaging format that preserves WebVTT
semantics while enabling efficient delivery through the MSF event timeline
infrastructure.

# Overview

## Mapping WebVTT to MSF Event Timelines

WebVTT content is delivered as an MSF event timeline track, which is a specialized
track type designed for time-synchronized metadata (see {{MSF, Section 11}}). The
mapping works as follows:

* **Track Declaration**: A WebVTT caption track is declared in the MSF catalog
  with `packaging` set to `eventtimeline` ({{MSF, Section 5.3.3}}) and `eventType`
  set to `urn:msf:captions:webvtt` ({{MSF, Section 5.3.4}}).

* **Cue Packaging**: Each WebVTT cue is converted to a JSON object and included
  in the event timeline's `data` field. The cue's start time determines its
  position in the timeline using the `m` (media time) index reference.

* **Timeline Synchronization**: The event timeline track declares a dependency
  on the video track it accompanies via the `depends` attribute ({{MSF, Section 5.3.14}}),
  enabling receivers to synchronize caption rendering with video playback.

* **MOQT Object Structure**: Following MSF event timeline conventions ({{MSF, Section 11.2}}),
  each MOQT Group begins with an independent object containing accumulated cue history,
  allowing subscribers joining mid-stream to receive necessary context.

## Carriage within MOQT

WebVTT caption tracks are carried as standard MSF event timeline tracks within
MOQT. The track shares the same namespace as the associated media content and
is listed in the catalog's `tracks` array. Subscribers receive caption data by
subscribing to the event timeline track, which delivers cue data synchronized
to media presentation timestamps.

The caption track MAY be encrypted using the content protection mechanisms
defined in {{MSF, Section 4.4}} when confidentiality is required.

# Conventions and Definitions

{::boilerplate bcp14-tagged}

# Cue Structure {#cue-structure}

Each WebVTT cue is mapped to an MSF event timeline record as defined in
{{MSF, Section 11.1}}. The record uses the `m` (media time) index reference
to indicate when the cue should be displayed, and the `data` field contains
a JSON object with the cue content.

The `data` object contains the following fields:

| Field    | Type   | Required | Description                        |
|:=========|:=======|:=========|:===================================|
| start    | Number | Yes      | Cue start time in milliseconds     |
| end      | Number | Yes      | Cue end time in milliseconds       |
| id       | String | No       | Cue identifier                     |
| text     | String | Yes      | Cue payload (may contain tags)     |
| settings | Object | No       | Positioning settings               |
| region   | String | No       | Region identifier                  |

The `text` field preserves WebVTT cue text tags (voice spans, timestamps, classes).
The `start` and `end` times are expressed in milliseconds to align with the media
time conventions used throughout MSF (see {{MSF, Section 10.1}}).

## Settings Object {#settings-object}

The optional `settings` object maps WebVTT cue settings to JSON properties:

| Field      | Type    | Description                            |
|:===========|:========|:=======================================|
| vertical   | String  | Writing direction: "rl" or "lr"        |
| line       | String  | Line position                          |
| position   | String  | Text position percentage               |
| size       | String  | Cue box size percentage                |
| align      | String  | Text alignment                         |

# Regions and Styles {#regions-styles}

WebVTT files may contain region definitions and CSS style blocks that apply
globally to all cues. These are delivered as a special initialization record
at the beginning of the event timeline (media time 0). This follows the MSF
pattern where track initialization data is provided at the start of a stream
(similar to {{MSF, Section 5.3.11}} for codec initialization).

Receivers MUST process this initialization record before rendering any cues.
The initialization record contains:

~~~json
{
    "m": 0,
    "data": {
        "regions": [
            {"id": "bottom", "width": "100%", "lines": 2,
             "regionAnchor": "50%,100%", "viewportAnchor": "50%,90%"}
        ],
        "styles": "::cue { background: rgba(0,0,0,0.8); }"
    }
}
~~~

# Event Timeline Track Structure {#track-structure}

A WebVTT caption event timeline track follows the structure defined in
{{MSF, Section 11.2}} for event timeline track updating:

* The first MOQT Object in each MOQT Group MUST be independent and contain
  all accumulated cue records up to that point. This allows subscribers
  joining at any group boundary to receive the complete caption history.

* Subsequent Objects within the same Group MAY contain incremental updates
  with only new cue records.

The event timeline uses the `m` (media presentation timestamp) index reference
for all cue records, as this provides the most direct synchronization with
video playback. The media time values in the index and within the cue data
MUST be consistent.

# Example {#example}

The following shows a complete event timeline track payload containing two
WebVTT cues. Each entry uses the MSF event timeline record format ({{MSF, Section 11.1}})
with the `m` index for media time synchronization:

~~~json
[
    {
        "m": 0,
        "data": {
            "start": 0,
            "end": 2500,
            "text": "Welcome to the show."
        }
    },
    {
        "m": 2500,
        "data": {
            "start": 2500,
            "end": 5000,
            "text": "<v Alice>Hello everyone!</v>",
            "settings": {"align": "center"}
        }
    }
]
~~~

The `m` value indicates when the cue becomes active and corresponds to the
`start` time within the data object. Receivers use this for timeline
synchronization while the `start` and `end` values within `data` define
the cue's display duration.

# Catalog Declaration {#catalog-declaration}

A WebVTT caption track is declared in the MSF catalog following the track
object structure defined in {{MSF, Section 5.3}}. The following fields are
particularly relevant:

* `packaging`: MUST be set to `eventtimeline` ({{MSF, Section 5.3.3}})
* `eventType`: MUST be set to `urn:msf:captions:webvtt` ({{MSF, Section 5.3.4}})
* `depends`: SHOULD list the video track(s) this caption track accompanies ({{MSF, Section 5.3.14}})
* `role`: SHOULD be set to `caption` or `subtitle` as appropriate ({{MSF, Section 5.3.6}})
* `lang`: SHOULD specify the caption language using RFC 5646 tags ({{MSF, Section 5.3.24}})
* `mimeType`: SHOULD be set to `application/json` ({{MSF, Section 5.3.17}})

Example catalog track declaration:

~~~json
{
    "name": "captions-en",
    "packaging": "eventtimeline",
    "eventType": "urn:msf:captions:webvtt",
    "mimeType": "application/json",
    "role": "caption",
    "lang": "en",
    "isLive": true,
    "depends": ["video"]
}
~~~

The `depends` attribute establishes a relationship between the caption track
and the video track it accompanies, enabling receivers to properly synchronize
caption rendering with video playback.

# Security Considerations

## Content Sanitization

Implementations MUST sanitize cue text before rendering to prevent injection
attacks. WebVTT cue text may contain markup tags that could be exploited if
passed directly to an HTML renderer. Receivers SHOULD:

* Validate that only permitted WebVTT tags are present (voice spans, timestamps,
  classes, bold, italic, underline, ruby)
* Escape or reject any HTML or script content not part of the WebVTT specification
* Limit the size of cue text to prevent denial-of-service attacks

## Content Protection

When caption content requires confidentiality (e.g., premium content with
translated subtitles), the event timeline track MAY be encrypted using the
mechanisms defined in {{MSF, Section 4.4}}.

# IANA Considerations

This document requests registration of the `urn:msf:captions:webvtt` event type
in the "MSF Event Timeline Types" registry established by {{MSF, Section 14.2}}:

| Event Type              | Description       | Specification |
|:========================|:==================|:==============|
| urn:msf:captions:webvtt | WebVTT caption cues | this document |

--- back

# Acknowledgments
{:numbered="false"}

Thanks to the MoQ working group.
