CREATE PROCEDURE dbo.spEM_DropReasonCategory
  @ReasonCatagory_Id int,
  @User_Id int
 AS
  --
  -- Return Codes: (0) Success
  --               (1) Sheet is active.
  --               (2) Sheet not found.
  --
  DECLARE @Insert_Id int
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropReasonCategory',
                 convert(nVarChar(10),@ReasonCatagory_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
   Delete From Event_Reason_Category_Data WHERE ERC_Id  = @ReasonCatagory_Id
   Delete From Event_Reason_Catagories Where ERC_Id  = @ReasonCatagory_Id
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
