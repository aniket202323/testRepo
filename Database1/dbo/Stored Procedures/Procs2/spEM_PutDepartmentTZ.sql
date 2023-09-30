CREATE PROCEDURE dbo.spEM_PutDepartmentTZ
  @TimeZone 	  	 nvarchar(255),
  @DeptId 	  	 Int,
  @UserId 	  	 int
 AS
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@UserId,'spEM_PutDepartmentTZ',
                substring(LTRIM(RTRIM(@TimeZone)) + ','  + 
                Convert(nVarChar(10),@DeptId) + ','  + 
                Convert(nVarChar(10),@UserId) ,1,255),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  UPDATE Departments SET  Time_Zone = @TimeZone  WHERE Dept_Id = @DeptId
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
