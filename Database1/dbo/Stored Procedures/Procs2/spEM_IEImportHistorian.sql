CREATE PROCEDURE dbo.spEM_IEImportHistorian
@Alias 	   	 nvarchar(50),
@Default 	 nVarChar(10),
@OS 	  	 nVarChar(100),
@HistType 	 nVarChar(100),
@ServerName 	 nVarChar(100),
@UserName 	 nVarChar(100),
@IsRemote 	 nVarChar(100),
@IsActive 	 nVarChar(100),
@HistOption 	 nVarChar(100),
@HistValue 	 nvarchar(2000),
@UserId 	  	 Int 	 
AS
Declare @iDefault 	 Int,
 	 @iOS  	  	 Int,
 	 @iHistType 	 Int,
 	 @iIsRemote 	 Int,
 	 @iIsActive 	 Int,
 	 @iHistid 	 Int
 	  	 
SELECT @Alias = RTrim(LTrim(@Alias))
SELECT @Default = RTrim(LTrim(@Default))
SELECT @OS = RTrim(LTrim(@OS))
SELECT @HistType = RTrim(LTrim(@HistType))
SELECT @ServerName = RTrim(LTrim(@ServerName))
SELECT @UserName = RTrim(LTrim(@UserName))
SELECT @IsRemote = RTrim(LTrim(@IsRemote))
SELECT @IsActive = RTrim(LTrim(@IsActive))
SELECT @HistOption = RTrim(LTrim(@HistOption))
SELECT @HistValue = RTrim(LTrim(@HistValue))
IF @Alias = ''  	  	 SELECT @Alias = Null
IF @Default = ''  	 SELECT @Default = Null
IF @OS = ''  	  	 SELECT @OS = Null
IF @HistType = ''  	 SELECT @HistType = Null
IF @ServerName = '' 	 SELECT @ServerName = Null
IF @UserName = '' 	 SELECT @UserName = Null
IF @IsRemote = '' 	 SELECT @IsRemote = Null
IF @IsActive = '' 	 SELECT @IsActive = Null
IF @HistOption = '' 	 SELECT @HistOption = Null
IF @HistValue = '' 	 SELECT @HistValue = Null
/************************************************************************/
/* Create/Update Data Types 	  	    	  	  	  	 */
/************************************************************************/
If @Alias IS NULL
 BEGIN
   SELECT  'Failed - Alias field is required'
   Return(-100)
 END
Select @iHistid = Hist_Id FROM Historians Where Alias = @Alias
Select @iDefault = 0
If isnumeric(@Default) = 0  and @Default is not null
BEGIN
 	 Select 'Failed - Default is not correct '
 	 Return(-100)
END 
IF @Default = '1' SELECT @iDefault = 1
SELECT @iOS = OS_Id FROM Operating_Systems WHERE OS_Desc = @OS
If @iOS IS NULL
BEGIN
 	 Select 'Failed - Operating Systems is not correct '
 	 Return(-100)
END 
SELECT @iHistType = Hist_Type_Id FROM Historian_Types WHERE Hist_Type_Desc = @HistType
If @iHistType IS NULL
BEGIN
 	 Select 'Failed - Historian Type not found'
 	 Return(-100)
END 
Select @iIsRemote = 0
If isnumeric(@IsRemote) = 0  and @IsRemote is not null
BEGIN
 	 Select 'Failed - Is Remote is not correct '
 	 Return(-100)
END 
IF @IsRemote = '1' SELECT @iIsRemote = 1
Select @iIsActive = 0
If isnumeric(@IsActive) = 0  and @IsActive is not null
BEGIN
 	 Select 'Failed - Is Remote is not correct '
 	 Return(-100)
END 
IF @IsActive = '1' SELECT @iIsActive = 1
/* Enough Info to create Historian*/
If @iHistid Is Null
BEGIN
 	 EXECUTE spEM_CreatePHN  @Alias,@UserId,@iHistid OUTPUT
 	 IF @iHistid Is NULL
 	 BEGIN
 	  	 Select 'Failed - error creating historian '
 	  	 Return(-100)
 	 END
END
DECLARE @PW nVarChar(100)
Select  	 @PW = Hist_Password,
 	 @ServerName  	 = Isnull(@ServerName,Hist_Servername),
 	 @UserName  	 = Isnull(@UserName,Hist_Username)
FROM Historians
Where Hist_Id = @iHistid
EXECUTE spCmn_Encryption2 @PW,'EncrYptoR',0,@PW Output
EXECUTE spEM_PutPHNData @iHistid,@UserName,@PW,@iOS,@iHistType,@ServerName,@iIsActive,@iIsRemote,@UserId
If @HistOption IS Not Null AND @HistValue Is Not Null
BEGIN
 	 DECLARE @HistOptionId Int,@FieldTypeId Int
 	 SELECT @HistOptionId = Hist_Option_Id,@FieldTypeId =  Field_Type_Id from Historian_options Where Hist_Option_Desc = @HistOption
 	 If @HistOptionId Is Null
 	 BEGIN
 	  	 Select 'Failed - historian option is not correct'
 	  	 Return(-100)
 	 END
 	 IF @FieldTypeId = 6
 	 BEGIN
 	  	 IF @HistValue Is Not NULL
 	  	 BEGIN
 	  	  	 IF @HistValue = '2' 
 	  	  	  	 SELECT @HistValue = 'TRUE'
 	  	  	 ELSE
 	  	  	  	 SELECT @HistValue = 'FALSE'
 	  	 END
 	 END
 	 EXECUTE spEM_PutPHNOptionData  @iHistid,@HistOptionId,@HistValue,@UserId
END
