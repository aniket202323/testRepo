CREATE FUNCTION dbo.fnServer_CmnGetSegRespCharacteristic(
@SegRespId uniqueidentifier
) 
     RETURNS int
AS 
begin
IF @SegRespId IS Null
      RETURN Null
declare @CharId int
set @CharId = NULL
select @CharId = Char_Id from S95_Event where S95_Guid = @SegRespId
--select @CharId = Char_Id from Characteristics where Char_Desc = Convert(nVarChar(50),dbo.fnServer_CmnGetSegRespWorkDefinitionSeqment(@SegRespId))
return @CharId
end
