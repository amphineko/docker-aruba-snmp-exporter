"""

Metric transforms for Aruba Mobility Controller SNMP metrics.

Telegraf is unable to extract indexed objects from the table, so the
is used to extract them from the index and re-insert them as tags.

For example, wlsxWlanAPStatsEntry is defined as:

    wlsxWlanAPStatsEntry OBJECT-TYPE 
        SYNTAX      WlanAPStatsEntry 
        MAX-ACCESS  not-accessible		
        STATUS      current 
        DESCRIPTION "Access Point Stats entry"
        INDEX {wlanAPMacAddress, wlanAPRadioNumber, wlanAPBSSID}
        ::= { wlsxWlanAPStatsTable 1 }

And the SNMP input plugin is configured as:

    [[inputs.snmp.table]]
        oid = "WLSX-WLAN-MIB::wlsxWlanAPStatsTable"
        name = "wlsxWlanAPStats"
        index_as_tag = true

        [[inputs.snmp.table.field]]
            oid = "WLSX-WLAN-MIB::wlanAPMacAddress"
            name = "wlanAPMacAddress"
            is_tag = true

        [[inputs.snmp.table.field]]
            oid = "WLSX-WLAN-MIB::wlanAPRadioNumber"
            name = "wlanAPRadioNumber"
            is_tag = true

        [[inputs.snmp.table.field]]
            oid = "WLSX-WLAN-MIB::wlanAPBSSID"
            name = "wlanAPBSSID"
            is_tag = true

In the above example, wlanAPMacAddress, wlanAPRadioNumber, and wlanAPBSSID
are actually not populated into the metric tags and are instead missing.

"""

load("logging.star", "log")

radio_types = {
    "1": "dot11a",
    "2": "dot11b",
    "3": "dot11g",
    "4": "dot11ag",
    "5": "wired",
    "6": "dot11ax6ghz",
}

def ip_address(segs):
    return ".".join([str(s) for s in segs])

def mac_address(segs):
    segs = ["%x" % int(x) for x in segs]
    segs = ["0" + x if len(x) == 1 else x for x in segs]
    return ":".join(segs)

def essid(segs):
    return "".join([chr(int(x, 10)) for x in segs])

def radio_type(segs):
    if segs[0] in radio_types:
        return radio_types[segs[0]]
    else:
        log.warn("unknown radio type %s" % segs[0])
        return segs[0]

def split_index_with_assert(metric, expected, min_expected = False):
    name, segments = metric.name, metric.tags["index"].split(".")
    metric.tags.pop("index")

    if len(segments) != expected and not min_expected:
        log.warn("%s index has %d segments, expected exactly %d" % (name, len(segments), expected))

    if len(segments) < expected and min_expected:
        log.warn("%s index has %d segments, expected at least %d" % (name, len(segments), expected))

    return segments

def apply(metric):
    if "index" not in metric.tags:
        return metric

    if metric.name == "wlsxSysXProcessor":
        index_segments = split_index_with_assert(metric, 1)
        metric.tags["sysXProcessorID"] = index_segments[0]

    if metric.name == "wlsxSysXMemory":
        index_segments = split_index_with_assert(metric, 1)
        metric.tags["wlsxSysXMemory"] = index_segments[0]

    if metric.name == "wlsxSwitchUser":
        index_segments = split_index_with_assert(metric, 4)
        metric.tags["userIpAddress"] = ip_address(reversed(index_segments[0:4]))

    if metric.name == "wlsxSwitchStationMgmt":
        index_segments = split_index_with_assert(metric, 12)
        metric.tags["staPhyAddress"] = mac_address(index_segments[0:6])
        metric.tags["staAccessPointBSSID"] = mac_address(index_segments[6:12])

    if metric.name == "wlsxSwitchStationStats":
        index_segments = split_index_with_assert(metric, 12)
        metric.tags["staPhyAddress"] = mac_address(index_segments[0:6])
        metric.tags["staAccessPointBSSID"] = mac_address(index_segments[6:12])

    if metric.name == "wlsxUser":
        index_segments = split_index_with_assert(metric, 10)
        metric.tags["nUserPhyAddress"] = mac_address(index_segments[0:6])
        metric.tags["nUserIpAddress"] = ip_address(index_segments[6:10])

    if metric.name == "wlsxWlanAP":
        index_segments = split_index_with_assert(metric, 6)
        metric.tags["wlanAPMacAddress"] = mac_address(index_segments[0:6])

    if metric.name == "wlsxWlanRadio":
        index_segments = split_index_with_assert(metric, 7)
        metric.tags["wlanAPMacAddress"] = mac_address(index_segments[0:6])
        metric.tags["wlanAPRadioNumber"] = index_segments[6]
        metric.tags["wlanAPRadioType"] = radio_type(metric.tags["wlanAPRadioType"])

    if metric.name == "wlsxWlanAPBssid":
        index_segments = split_index_with_assert(metric, 13)
        metric.tags["wlanAPMacAddress"] = mac_address(index_segments[0:6])
        metric.tags["wlanAPRadioNumber"] = index_segments[6]
        metric.tags["wlanAPBSSID"] = mac_address(index_segments[7:13])

    if metric.name == "wlsxWlanStation":
        index_segments = split_index_with_assert(metric, 6)
        metric.tags["wlanStaPhyAddress"] = mac_address(index_segments[0:6])
        metric.tags["wlanStaPhyType"] = radio_type(metric.tags["wlanStaPhyType"])

    if metric.name == "wlsxWlanStaAssociationFailure":
        index_segments = split_index_with_assert(metric, 12)
        metric.tags["wlanStaPhyAddress"] = mac_address(index_segments[0:6])
        metric.tags["wlanAPBSSID"] = mac_address(index_segments[6:12])

    if metric.name == "wlsxWlanAPStats":
        index_segments = split_index_with_assert(metric, 13)
        metric.tags["wlanAPMacAddress"] = mac_address(index_segments[0:6])
        metric.tags["wlanAPRadioNumber"] = index_segments[6]
        metric.tags["wlanAPBSSID"] = mac_address(index_segments[7:13])

    if metric.name == "wlsxWlanAPFrameTypeStats":
        index_segments = split_index_with_assert(metric, 13)
        metric.tags["wlanAPMacAddress"] = mac_address(index_segments[0:6])
        metric.tags["wlanAPRadioNumber"] = index_segments[6]
        metric.tags["wlanAPBSSID"] = mac_address(index_segments[7:13])

    if metric.name == "wlsxWlanAPChStats":
        index_segments = split_index_with_assert(metric, 7)
        metric.tags["wlanAPMacAddress"] = mac_address(index_segments[0:6])
        metric.tags["wlanAPRadioNumber"] = index_segments[6]

    if metric.name == "wlsxWlanAPESSIDStats":
        index_segments = split_index_with_assert(metric, 7, 7)
        metric.tags["wlanAPMacAddress"] = mac_address(index_segments[0:6])
        metric.tags["wlanESSID"] = essid(index_segments[6 + 1:])

    if metric.name == "wlsxWlanAPRadioStatsTable":
        index_segments = split_index_with_assert(metric, 7)
        metric.tags["wlanAPMacAddress"] = mac_address(index_segments[0:6])
        metric.tags["wlanAPRadioNumber"] = index_segments[6]

    if metric.name == "wlsxWlanStationStatsTable":
        index_segments = split_index_with_assert(metric, 6)
        metric.tags["wlanStaPhyAddress"] = mac_address(index_segments[0:6])

    if metric.name == "wlsxWlanStaFrameTypeStatsTable":
        index_segments = split_index_with_assert(metric, 6)
        metric.tags["wlanStaPhyAddress"] = mac_address(index_segments[0:6])

    return metric
