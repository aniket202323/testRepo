CREATE PROCEDURE dbo.spEM_SheetOptionRT
@id Int
AS
select Binary_Id,Image from Binaries  where Binary_Id = @id
