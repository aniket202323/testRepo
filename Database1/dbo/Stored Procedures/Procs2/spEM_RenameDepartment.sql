CREATE PROCEDURE dbo.spEM_RenameDepartment
  @Dept_Id       int,
  @Description nvarchar(50),
  @User_Id int
 AS
  DECLARE @Insert_Id integer
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_RenameDepartment',Convert(nVarChar(10),@Dept_Id) + ','  + 
                @Description + ','  + Convert(nVarChar(10),@User_Id),dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Codes:
  --
  --   0 = Success
  --
 	 If (@@Options & 512) = 0
 	  	 Update Departments_Base Set Dept_Desc_Global = @Description Where Dept_Id = @Dept_Id
 	 Else
 	  	 Update Departments_Base Set Dept_Desc = @Description Where Dept_Id = @Dept_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
