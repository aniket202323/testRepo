CREATE PROCEDURE dbo.spServer_StbGetTimeTestFreqs 
@MasterUnit int,
@Prod_Id int,
@RunStartTime datetime,
@SheetId int = 0
 AS
Declare
  @CurrentTime datetime
If (@RunStartTime is null)
 Select @RunStartTime = '1-Jan-1970 00:00:00'
Select @CurrentTime = dbo.fnServer_CmnGetDate(GetUTCDate())
Declare @TestFreqInfo Table(Var_Desc nvarchar(200) COLLATE DATABASE_DEFAULT, Var_Id int, PU_Id int, SampInt int, SampOff int, Test_Freq int, TF_Reset int, Orig_Freq int null, Debug int null)
Insert Into @TestFreqInfo(Var_Desc,Var_Id,PU_Id,SampInt,SampOff,TF_Reset,Test_Freq,Orig_Freq,Debug) 
(Select Var_Desc = a.Var_Desc,
       Var_Id = a.Var_Id,
       PU_Id = a.PU_Id,
       SampInt = a.Sampling_Interval,
       SampOff = COALESCE(a.Sampling_Offset,0),
       TFReset = COALESCE(a.TF_Reset,0),
       Test_Freq = COALESCE(b.Test_Freq,1),
       Orig_Freq = b.Test_Freq,
 	  	  	  Debug = a.Debug
  From Variables_Base a 
  Left Outer Join Var_Specs b on (a.Var_Id = b.Var_Id) And 
 	  	  	  	  (b.Prod_Id = @Prod_Id) And
         	  	  	  (b.Effective_Date <= @CurrentTime) And 
         	  	  	  ((b.Expiration_Date > @CurrentTime) Or (b.Expiration_Date Is Null))
  Where (a.Is_Active = 1) And 
        (a.DS_Id In (2,11,14,16)) And 
        (a.SA_Id = 1) And
        (a.Event_Type in (0,5,26,28)) And
        ((a.Repeating Is Null) Or (a.Repeating = 0)) And
        (a.PU_Id In (Select PU_Id From Prod_Units_Base Where (PU_Id = @MasterUnit) Or (Master_Unit = @MasterUnit))) And
        (a.Sampling_Interval >= 1) And
        (a.Sampling_Interval Is Not Null)
)
Insert Into @TestFreqInfo(Var_Desc,Var_Id,PU_Id,SampInt,SampOff,TF_Reset,Test_Freq,Orig_Freq, Debug) 
(Select Var_Desc = a.Var_Desc,
       Var_Id = a.Var_Id,
       PU_Id = a.PU_Id,
       SampInt = a.Sampling_Interval,
       SampOff = COALESCE(a.Sampling_Offset,0),
       TFReset = COALESCE(a.TF_Reset,0),
       Test_Freq = COALESCE(b.Test_Freq,1),
       Orig_Freq = b.Test_Freq,
 	  	  	  Debug = a.Debug
  From Variables_Base a 
  Left Outer Join Var_Specs b on (a.Var_Id = b.Var_Id) And 
 	  	  	  	  (b.Prod_Id = @Prod_Id) And
         	  	  	  (b.Effective_Date <= @RunStartTime) And 
         	  	  	  ((b.Expiration_Date > @RunStartTime) Or (b.Expiration_Date Is Null))
  Where (a.Is_Active = 1) And 
        (a.DS_Id In (2,11,14,16)) And 
        (a.SA_Id = 2) And
        (a.Event_Type in (0,5,26,28)) And
        ((a.Repeating Is Null) Or (a.Repeating = 0)) And
        (a.PU_Id In (Select PU_Id From Prod_Units_Base Where (PU_Id = @MasterUnit) Or (Master_Unit = @MasterUnit))) And
        (a.Sampling_Interval >= 1) And
        (a.Sampling_Interval Is Not Null)
)
-- The Sheet Id is for a No Interval Time Based Sheet
if (@SheetId > 0)
  begin
    Delete From @TestFreqInfo
           Where Var_Id not in (select v.Var_Id
                                  from Sheets s join Sheet_Variables v on s.Sheet_Id = v.Sheet_Id
                                  where s.Sheet_Id = @SheetId
                                    and s.Is_Active = 1
                                    and s.Sheet_Type = 1
                                    and s.Interval = 0 and v.var_id is not null)
    update @TestFreqInfo set Test_Freq = SampInt where Orig_Freq is null
  end
else
  Delete From @TestFreqInfo
         Where Var_Id in (select v.Var_Id
                          from Sheets s join Sheet_Variables v on s.Sheet_Id = v.Sheet_Id
                          where s.Is_Active = 1
                            and s.Sheet_Type = 1
                            and s.Interval = 0 and v.var_id is not null)
Delete From @TestFreqInfo Where Test_Freq = 0
Select Var_Id = Var_Id,
       PU_Id = PU_Id,
       SampInt = SampInt,
       SampOff = SampOff,
       Test_Freq = Test_Freq,
       TFReset = TF_Reset,
       TZName = dbo.fnServer_GetTimeZone(PU_Id),
 	  	  	  Debug = Debug
  From @TestFreqInfo
  Order by PU_Id, Var_Desc
