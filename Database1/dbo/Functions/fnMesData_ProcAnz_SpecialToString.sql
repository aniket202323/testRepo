CREATE FUNCTION [dbo].[fnMesData_ProcAnz_SpecialToString](
        @name nvarchar(900) = NULL
)
RETURNS  nvarchar(900)
AS
BEGIN
    SET @name = ISNULL(@name, '')
    SET @name = REPLACE(@name, '[', '[[]');
    SET @name = REPLACE(@name, '_', '[_]');
    SET @name = REPLACE(@name, '%', '[%]');
    SET @name = REPLACE(@name, '*', '[*]');
return @name
END
