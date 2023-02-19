function make_timestamp(outstr)
    if timestamp then
        local ts = os.date(string.format('\31\%c[%s]\30\01 ', timestamp_color, timestamp_format))
        return ts .. outstr
    else
        return outstr
    end
end