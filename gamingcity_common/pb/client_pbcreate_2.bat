for /r %%s in (common_*.proto) do (
	protoc.exe -I . --descriptor_set_out client/%%~ns.proto %%~ns.proto
)