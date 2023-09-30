CREATE PROCEDURE dbo.spBF_calCrewAddUpdateDelete
 	  	 @TransType 	  	 Int,
 	  	 @CrewId 	  	  	 Int,
        @crewName 	  	 nvarchar(10),
        @crewDesc 	  	 nvarchar(50),
 	  	 @ModifyUserId 	 Int = 1
AS
SET NOCOUNT ON
IF @ModifyUserId Is Null SET @ModifyUserId =1
IF @TransType = 1
BEGIN
 	 SELECT @CrewId = Null
 	 select @CrewId=Id from Crews where Name = @crewName and IsDeleted=1
 	 if @CrewId is null 
 	 begin
 	  	 insert into Crews (Name,Description,Update_User_Id, Modified_On, IsDeleted) 
 	  	  	 SELECT @crewName, @crewDesc, @ModifyUserId, GETUTCDATE(),0
 	  	 select @CrewId=Id from Crews where Name = @crewName
 	 end
 	 else 
 	 begin
 	  	 update Crews set IsDeleted=0,Name=@crewName,Description=@crewDesc,Update_User_Id=@ModifyUserId, Modified_On=GETUTCDATE()
 	  	  where Id = @CrewId
 	 end 
END
ELSE IF @TransType = 2
BEGIN
  update Crews set Name=@crewName,Description=@crewDesc,Update_User_Id=@ModifyUserId, Modified_On=GETUTCDATE() 
  where Id = @CrewId
END
ELSE IF @TransType = 3
BEGIN
 	  update Crews set name=convert(nvarchar(10), id)  + name,IsDeleted=1,Update_User_Id=@ModifyUserId, Modified_On=GETUTCDATE() 
 	  	 where Id = @CrewId
 	 SELECT 'Success'
 	 Return
END
IF @TransType In (1,2)
BEGIN
  select Id,Description,Name,Update_User_Id,Modified_On,IsDeleted from Crews where Id =  @CrewId 
END
