fn write_uint16_be file intVal = (
	WriteByte file (intVal / 256)
	WriteByte file (mod intVal 256)
)

fn write_float_be file floatVal = (
	local pos = ftell file
	WriteFloat file floatVal
	fseek file pos #seek_set
	fflush file
	local byte0 = ReadByte file #unsigned
	local byte1 = ReadByte file #unsigned
	local byte2 = ReadByte file #unsigned
	local byte3 = ReadByte file #unsigned
	fseek file pos #seek_set
	WriteByte file byte3
	WriteByte file byte2
	WriteByte file byte1
	WriteByte file byte0
)