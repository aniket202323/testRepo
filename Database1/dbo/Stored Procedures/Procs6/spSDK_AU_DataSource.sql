CREATE procedure [dbo].[spSDK_AU_DataSource]
@AppUserId int,
@Id int OUTPUT,
@DataSource nvarchar(50) ,
@IsActive tinyint 
AS
DECLARE @OldActive TinyInt
Insert into Audit_Trail(Application_id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@AppUserId,'spSDK_AU_DataSource',  Coalesce(convert(varchar(10),@Id),'Null') + ','  + 
 	  	  	  	  	 Coalesce(Convert(varchar(1), @IsActive),'Null') + ','  + @DataSource ,dbo.fnServer_CmnGetDate(getUTCdate()))
IF @Id IS NOT NULL
BEGIN
 	 IF Not Exists(SELECT 1 FROM Data_Source WHERE DS_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Data Source not found for update'
 	  	 RETURN(-100)
 	 END
 	 IF @Id IN(4,50000)
 	 BEGIN
 	  	 SELECT 'Data Source is not updatable'
 	  	 Return(-100)
 	 END
 	 SELECT @OldActive = Active FROM Data_Source WHERE DS_Id = @Id
 	 SET @IsActive = Coalesce(@IsActive,@OldActive)
 	 IF  @IsActive = 0
 	 BEGIN
 	  	 IF EXISTS (Select 1 from Variables_Base as Variables Where Ds_Id = @Id Or Write_Group_DS_Id =  @Id)
 	  	 BEGIN
 	  	  	 SELECT 'Data Source is in use - cannot deactivate'
 	  	  	 RETURN(-100)
 	  	 END
 	 END
 	 IF @Id < 50000
 	 BEGIN
 	  	 UPDATE Data_Source SET Active = @IsActive WHERE Ds_Id = @Id
 	 END
 	 ELSE
 	 BEGIN
 	  	 UPDATE Data_Source SET Active = @IsActive,DS_Desc = @DataSource WHERE Ds_Id = @Id
 	 END
END
ELSE
BEGIN
 	 SELECT @Id = DS_Id 
 	  	 FROM Data_Source 
 	  	 WHERE DS_Desc = @DataSource
 	 IF @Id Is Not Null
 	 BEGIN
 	  	  	 SELECT 'Data Source already exists - add failed'
 	  	  	 RETURN(-100)
 	 END
 	 /* Add ignores is-active (always create as active)*/
 	 EXECUTE spEM_CreateDataSource @DataSource,@AppUserId,@Id OUTPUT
 	 IF @Id Is Null
 	 BEGIN
 	  	  	 SELECT 'Data Source add failed'
 	  	  	 RETURN(-100)
 	 END
 	 Update Data_Source Set Active = @IsActive Where DS_Id = @Id
END
Return(1)
