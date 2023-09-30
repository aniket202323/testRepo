CREATE PROCEDURE dbo.spEM_StatusColorSave (@color int,@id int)
AS
update Colors set Color=@color where Color_Id=@id
