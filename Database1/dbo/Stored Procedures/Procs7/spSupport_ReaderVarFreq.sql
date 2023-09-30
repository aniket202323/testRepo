Create Procedure dbo.spSupport_ReaderVarFreq
AS
set nocount on
Declare @VarId  Int
Declare @SheetId Int
Declare @Interval Int, @Sheet_Desc VarChar(100)
Create Table #O([Id] Int,[Description] VarChar(50),[Frequency] Int,[Sheet Interval] Int Null ,[Display] VarChar(100)Null ,[Tag] VarChar(100))
Insert Into #O ([Id],[Description],[Frequency],[Sheet Interval],[Display] ,[Tag] )
  Select v.Var_Id,Var_Desc, Sampling_Interval,Null,Null,Input_Tag
 	 From variables v
 	 Where Sampling_Interval < 10 and DS_Id = 3 and v.Event_Type = 0 and PU_Id > 0
Declare ReaderVarFreqCursor Cursor For 
 	 Select Var_Id From variables 
 	 Where Sampling_Interval < 10 and DS_Id = 3 and Event_Type = 0 and PU_Id > 0
Open ReaderVarFreqCursor
ReaderVarLoop:
Fetch Next From ReaderVarFreqCursor Into @VarId
If @@Fetch_Status = 0
  Begin
 	 Select @SheetId = Null,@Sheet_Desc = Null,@Sheet_Desc = Null,@Interval = Null
 	 Select @SheetId = Min(sv.Sheet_Id) 
 	  	 From Sheet_Variables sv
 	  	 Join Sheets s on s.Sheet_Id  = sv.Sheet_Id and s.Sheet_Type in (1,16)
 	  	 Where Var_Id = @VarId
 	 Select @Sheet_Desc =Sheet_Desc ,@Interval = Interval From Sheets  Where Sheet_Id = @SheetId 
 	 Update  	 #O Set [Sheet Interval] = @Interval,[Display] = @Sheet_Desc Where [Id] =  @VarId
 	 Goto ReaderVarLoop
  End
Close ReaderVarFreqCursor
Deallocate ReaderVarFreqCursor
Select * From #O
Drop Table #O
set nocount off
