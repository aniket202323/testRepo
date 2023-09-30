CREATE PROCEDURE dbo.spServer_EMgrGet0095Specs
@MasterUnit int,
@SpecType nVarChar(30)
 AS
Declare
  @Prod_Id int
Select @Prod_Id = Prod_Id
  From Production_Starts
  Where (PU_Id = @MasterUnit) And
        (End_Time Is Null)
Declare @AcqVars Table(MasterUnit int NULL, PU_Id int, Var_Id int, Var_Desc nVarChar(100) COLLATE DATABASE_DEFAULT, Data_Type_Id int, Sampling_Type int, Input_Tag nVarChar(100) COLLATE DATABASE_DEFAULT NULL, WorkCenter nvarchar(20) COLLATE DATABASE_DEFAULT NULL, TestCode nVarChar(30) COLLATE DATABASE_DEFAULT NULL, SampType nvarchar(20) COLLATE DATABASE_DEFAULT NULL)
Insert Into @AcqVars (MasterUnit,PU_Id,Var_Id,Var_Desc,Data_Type_Id,Sampling_Type,Input_Tag)
(Select b.Master_Unit,a.PU_Id,a.Var_Id,a.Var_Desc,a.Data_Type_Id,Sampling_Type = COALESCE(a.Sampling_Type,0),a.Input_Tag
  From Variables_Base a
  Join Prod_Units_Base b on b.PU_Id = a.PU_Id
  Where (a.DS_Id = 11) And
        (a.Event_Type = 1) And
        (a.Input_Tag Is Not Null) And
        (a.Input_Tag Not Like '%/NOSPEC%') And
        (CharIndex('\',a.Input_Tag) > 0))
Update @AcqVars
  Set MasterUnit = PU_Id
  Where MasterUnit Is Null
Delete From @AcqVars Where MasterUnit <> @MasterUnit
Update @AcqVars
  Set WorkCenter = SubString(Input_Tag,1,CharIndex('\',Input_Tag) - 1)
Update @AcqVars
  Set Input_Tag = SubString(Input_Tag,CharIndex('\',Input_Tag) + 1,200)
Delete From @AcqVars Where (CharIndex('\',Input_Tag) = 0) Or (Input_Tag Is Null)
Update @AcqVars
  Set TestCode = SubString(Input_Tag,1,CharIndex('\',Input_Tag) - 1)
Update @AcqVars
  Set Input_Tag = SubString(Input_Tag,CharIndex('\',Input_Tag) + 1,200)
Delete From @AcqVars Where (Input_Tag Is Null)
Update @AcqVars
  Set SampType = Input_Tag
If (@SpecType = 'WARNING')
  Begin
    Select TestCode = b.TestCode, ProdCode = c.Prod_Code, Lower = COALESCE(a.L_Warning,''), Upper = COALESCE(a.U_Warning,'')
      From Var_Specs a
      Join @AcqVars b on b.Var_Id = a.Var_Id
      Join Products c on c.Prod_Id = a.Prod_Id And (c.Prod_Id = @Prod_Id)
      Where (a.Expiration_Date Is Null)
  End
Else
  Begin
    Select TestCode = b.TestCode, ProdCode = c.Prod_Code, Lower = COALESCE(a.L_Reject,''), Upper = COALESCE(a.U_Reject,'')
      From Var_Specs a
      Join @AcqVars b on b.Var_Id = a.Var_Id
      Join Products c on c.Prod_Id = a.Prod_Id
      Where (a.Expiration_Date Is Null)
  End
