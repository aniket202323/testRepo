Create Procedure dbo.spMSITopic_VariableSpecificationChange
@value int OUTPUT,
@Key int,
@Topic int
as
Declare @CurrentTime            DateTime,
        @Topic_Interval         Integer, 
        @StartTime              DateTime, 
        @LastTran               DateTime,
        @NextRun                DateTime
Select @CurrentTime = dbo.fnServer_CmnGetDate(getUTCdate())
select @Topic_Interval = (Sampling_Interval + 10) From Topics Where Topic_Id = @Topic
select @StartTime = Dateadd(n, -1 * @Topic_Interval, @CurrentTime)
Select TOP 1 @LastTran = Approved_On From Transactions order by Approved_On DESC
If @StartTime > @LastTran -- Approved specs since last run?
  BEGIN
    return
  END
if @Topic = 110
  begin
    -- left over to handle old clients
    Select Type = 4, Topic = @Topic, KeyValue = @Key, EffectiveDate = Convert(VarChar(25), vs.Effective_Date, 120), DeviationFrom = vs.Deviation_From, FirstException = vs.First_Exception,
           ExpirationDate = Convert(VarChar(25), vs.Expiration_Date, 120), TestFreq = vs.Test_Freq, CommentId = vs.Comment_Id, VarId = vs.Var_Id, ProdId = vs.Prod_Id, 
           IsOverRiden = vs.Is_OverRiden, IsDeviation = vs.Is_Deviation, IsOverRidable = vs.Is_OverRidable,
           IsDefined = vs.Is_Defined, IsLRejectable = vs.Is_L_Rejectable, IsURejectable = vs.Is_U_Rejectable,
           LWarning = vs.L_Warning, LReject = vs.L_Reject, LEntry = vs.L_Entry, LUser = vs.L_User, Target = vs.Target,
           UWarning = vs.U_Warning, UReject = vs.U_Reject, UEntry = vs.U_Entry, UUser = vs.U_User,
           DataTypeId = v.Data_Type_Id, VSId = vs.VS_Id, ESignatureLevel = Coalesce(Coalesce(vs.ESignature_Level,v.ESignature_Level), 0), SAId = v.SA_Id
            From Var_Specs vs WITH (index(VarSpecs_IDX_EffExp) NOLOCK)
             Join Variables v on v.Var_Id = vs.Var_Id and SA_Id = 1
              Where (vs.Effective_date >= @StartTime AND
                     vs.Effective_date <= @CurrentTime) AND
              ((vs.Expiration_date > @CurrentTime) OR 
               (vs.Expiration_date IS NULL))
          OPTION (MAXDOP 4)
  end
else if @Topic = 111
  -- For ALC spec cache: only retrieve variables that are on the sheet indicated in the key.
  begin
    Select Type = 4, Topic = @Topic, KeyValue = @Key, EffectiveDate = Convert(VarChar(25), vs.Effective_Date, 120), DeviationFrom = vs.Deviation_From, FirstException = vs.First_Exception,
           ExpirationDate = Convert(VarChar(25), vs.Expiration_Date, 120), TestFreq = vs.Test_Freq, CommentId = vs.Comment_Id, VarId = vs.Var_Id, ProdId = vs.Prod_Id, 
           IsOverRiden = vs.Is_OverRiden, IsDeviation = vs.Is_Deviation, IsOverRidable = vs.Is_OverRidable,
           IsDefined = vs.Is_Defined, IsLRejectable = vs.Is_L_Rejectable, IsURejectable = vs.Is_U_Rejectable,
           LWarning = vs.L_Warning, LReject = vs.L_Reject, LEntry = vs.L_Entry, LUser = vs.L_User, Target = vs.Target,
           UWarning = vs.U_Warning, UReject = vs.U_Reject, UEntry = vs.U_Entry, UUser = vs.U_User,
           DataTypeId = v.Data_Type_Id, VSId = vs.VS_Id, ESignatureLevel = Coalesce(Coalesce(vs.ESignature_Level,v.ESignature_Level), 0), SAId = v.SA_Id
            From Var_Specs vs WITH (index(VarSpecs_IDX_EffExp) NOLOCK)
             Join Variables v on v.Var_Id = vs.Var_Id and SA_Id = 1
             Join Sheet_Variables sv on sv.var_id = v.var_id and sv.sheet_id = @Key
              Where (vs.Effective_date >= @StartTime AND
                     vs.Effective_date <= @CurrentTime) AND
              ((vs.Expiration_date > @CurrentTime) OR 
               (vs.Expiration_date IS NULL))
          OPTION (MAXDOP 4)
  end
else if @Topic = 112
  begin
    -- ECR #32964 the ProfSVR.SpecificationCache is only used by the ProfRVW & ProfTRD controls so 
    -- only return specs that are on a sheet of that type.
    -- If its used by more than that in the future, add them below
    Declare @Vars       Table (Var_Id int, Data_Type_Id int, ESignature_Level int, SA_Id int)
    Declare @VarsUnique Table (Var_Id int, Data_Type_Id int, ESignature_Level int, SA_Id int)
    -- get all Trend Variables
    Insert into @Vars (Var_Id, Data_Type_Id, ESignature_Level, SA_Id) 
      Select sp.Var_Id1, v.Data_Type_Id, v.ESignature_Level, v.SA_Id
       from Sheet_Plots sp
       join Variables v on v.Var_id = sp.Var_id1
       where Var_Id1 is not null 
    Insert into @Vars (Var_Id, Data_Type_Id, ESignature_Level, SA_Id) 
      Select sp.Var_Id2, v.Data_Type_Id, v.ESignature_Level, v.SA_Id
       from Sheet_Plots sp
       join Variables v on v.Var_id = sp.Var_id2
       where Var_Id2 is not null 
    Insert into @Vars (Var_Id, Data_Type_Id, ESignature_Level, SA_Id) 
      Select sp.Var_Id3, v.Data_Type_Id, v.ESignature_Level, v.SA_Id
       from Sheet_Plots sp
       join Variables v on v.Var_id = sp.Var_id3
       where Var_Id3 is not null 
    Insert into @Vars (Var_Id, Data_Type_Id, ESignature_Level, SA_Id) 
      Select sp.Var_Id4, v.Data_Type_Id, v.ESignature_Level, v.SA_Id
       from Sheet_Plots sp
       join Variables v on v.Var_id = sp.Var_id4
       where Var_Id4 is not null 
    Insert into @Vars (Var_Id, Data_Type_Id, ESignature_Level, SA_Id) 
      Select sp.Var_Id5, v.Data_Type_Id, v.ESignature_Level, v.SA_Id
       from Sheet_Plots sp
       join Variables v on v.Var_id = sp.Var_id5
       where Var_Id5 is not null 
    -- get all Relative View Variables
    Insert into @Vars (Var_Id, Data_Type_Id, ESignature_Level, SA_Id) 
      Select sv.Var_Id, v.Data_Type_Id, v.ESignature_Level, v.SA_Id
       from Sheet_Variables sv
       join Sheets s on s.Sheet_id = sv.Sheet_id and s.Sheet_Type = 9
       join Variables v on v.Var_id = sv.Var_id
    -- Select Distinct Var_Ids - tried unique constraint on @Vars but I didn't like that it returned an error.
    Insert into @VarsUnique (Var_Id, Data_Type_Id, ESignature_Level, SA_Id) 
      Select Distinct Var_Id, Data_Type_Id, ESignature_Level, SA_Id from @Vars
    Select Type = 4, Topic = @Topic, KeyValue = @Key, EffectiveDate = Convert(VarChar(25), vs.Effective_Date, 120), DeviationFrom = vs.Deviation_From, FirstException = vs.First_Exception,
           ExpirationDate = Convert(VarChar(25), vs.Expiration_Date, 120), TestFreq = vs.Test_Freq, CommentId = vs.Comment_Id, VarId = vs.Var_Id, ProdId = vs.Prod_Id, 
           IsOverRiden = vs.Is_OverRiden, IsDeviation = vs.Is_Deviation, IsOverRidable = vs.Is_OverRidable,
           IsDefined = vs.Is_Defined, IsLRejectable = vs.Is_L_Rejectable, IsURejectable = vs.Is_U_Rejectable,
           LWarning = vs.L_Warning, LReject = vs.L_Reject, LEntry = vs.L_Entry, LUser = vs.L_User, Target = vs.Target,
           UWarning = vs.U_Warning, UReject = vs.U_Reject, UEntry = vs.U_Entry, UUser = vs.U_User,
           DataTypeId = v.Data_Type_Id, VSId = vs.VS_Id, ESignatureLevel = Coalesce(Coalesce(vs.ESignature_Level,v.ESignature_Level), 0), SAId = v.SA_Id
            From Var_Specs vs WITH (index(VarSpecs_IDX_EffExp) NOLOCK)
             Join @VarsUnique v on v.Var_Id = vs.Var_Id 
              Where (vs.Effective_date >= @StartTime AND
                     vs.Effective_date <= @CurrentTime) AND
              ((vs.Expiration_date > @CurrentTime) OR 
               (vs.Expiration_date IS NULL))
          OPTION (MAXDOP 4)
  end
