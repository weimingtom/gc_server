
local logger = {}

function logger.info(format, ...)
    print(string.format("[INFO]      " .. format, ...))
end

function logger.trace(format, ...)
    print(string.format("[TRACE]     " .. format, ...))
end

function logger.debug(format, ...)
    print(string.format("[DEBUG]     " .. format, ...))
end

function logger.warning(format, ...)
    print(string.format("[WARNING]   " .. format, ...))
end

function logger.exception(format, ...)
    print(string.format("[EXCEPTION] " .. format, ...))
end

function logger.error(format, ...)
    print(string.format("[ERROR]     " .. format, ...))
end

return logger
