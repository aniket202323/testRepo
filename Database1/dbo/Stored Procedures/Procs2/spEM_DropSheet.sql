CREATE PROCEDURE dbo.spEM_DropSheet
  @Sheet_Id int,
  @User_Id int
 AS
  --
  -- Return Codes: (0) Success
  --               (1) Sheet is active.
  --               (2) Sheet not found.
  --
  DECLARE @Insert_Id int,
 	       @Is_Active int,
 	       @SId          int,
 	       @RsltOn     DateTime
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropSheet',
                 convert(nVarChar(10),@Sheet_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --Create Table #Cols(Sheet_Id int,Result_On  DateTime)
  --Insert into #Cols Select Sheet_id,Result_On From Sheet_Columns Where Sheet_Id = @Sheet_Id
  BEGIN TRANSACTION
--  Execute('Declare Col_Cursor Cursor Global For Select Sheet_Id,Result_On From #Cols For Read Only')
--  Open Col_Cursor  
--FetchNext:
--  Fetch Next From Col_Cursor into @SId,@RsltOn
--  If @@Fetch_status = 0 
-- 	 Begin
-- 	     DELETE FROM Sheet_Columns WHERE Sheet_Id = @SId And Result_On = @RsltOn
-- 	     GoTo FetchNext 
-- 	 End
--  Close Col_Cursor
--  Deallocate Col_Cursor
--  Drop Table #Cols
  Delete from Sheet_Columns where Sheet_Id = @Sheet_Id
  Delete FROM Sheet_Variables WHERE Sheet_Id = @Sheet_Id
  Select Binary_Id into #BIds From  Sheet_Display_Options Where Sheet_Id = @Sheet_Id
  Delete From Sheet_Display_Options Where Sheet_Id = @Sheet_Id
  Delete From Binaries Where Binary_Id in (select Binary_Id from #BIds)
  Drop Table #BIds
  Delete From Sheet_Unit Where Sheet_Id = @Sheet_Id
  Delete From Staged_Sheet_Variables where  Sheet_Id = @Sheet_Id
  Delete FROM Sheet_Plots WHERE Sheet_Id = @Sheet_Id
  Delete From Staged_Plot_Variables where  Sheet_Id = @Sheet_Id
  Delete From Sheet_Genealogy_Data where  Sheet_Id = @Sheet_Id
  Delete From Sheet_Paths where  Sheet_Id = @Sheet_Id
  Delete From Sheet_Genealogy_Data where  Display_Sheet_Id = @Sheet_Id
  Delete FROM Sheets WHERE Sheet_Id = @Sheet_Id
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
