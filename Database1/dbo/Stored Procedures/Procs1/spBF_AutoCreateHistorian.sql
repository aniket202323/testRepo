CREATE Procedure dbo.spBF_AutoCreateHistorian
@InHistName nvarchar(100),
@UserId  Int,
@HistAliasName nVarChar(100) OUTPUT
AS
IF @InHistName is Null
 	 RETURN
DECLARE @Counter Int
DECLARE @HistId Int
SELECT @HistAliasName = Min(alias) from Historians WHERE Hist_Servername = @InHistName and Hist_Type_Id = 9
IF @HistAliasName Is Null -- attempt add a historian
BEGIN
 	 SET @Counter = 2
 	 IF LEN(@InHistName) < 50
 	  	 SELECT @HistAliasName = @InHistName
 	 ELSE
 	  	 SELECT  @HistAliasName = 'Auto[1]'
 	 WHILE Exists(select 1 from Historians WHERE Alias = @HistAliasName)
 	 BEGIN
 	  	 SELECT @HistAliasName = 'Auto [' + CONVERT(nvarchar(2),@Counter)  + ']'
 	  	 SET @Counter = @Counter + 1
 	 END
 	 EXECUTE spEM_CreatePHN   @HistAliasName,@UserId,@HistId Output
 	 EXECUTE spEM_PutPHNData    @HistId,null,null,2,9,@InHistName,1,0,@UserId
END
