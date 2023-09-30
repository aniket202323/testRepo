CREATE PROCEDURE dbo.spServer_EMgrGet0650Specs
@MasterUnit int,
@ProdId int,
@TimeStamp datetime
AS
Declare @M650Vars Table(Var_Id int, DefTestFreq int NULL)
Insert Into @M650Vars (Var_Id,DefTestFreq)
(Select Var_Id,Sampling_Interval
  From Variables_Base 
  Where (Event_Type = 1) And
        (Is_Conformance_Variable = 1) And
 	 PU_Id in (Select PU_Id From Prod_Units_Base Where (PU_Id = @MasterUnit) or (Master_Unit = @MasterUnit)))
Select a.Var_Id,b.L_Entry,b.L_Reject,b.L_Warning,b.L_User,b.Target,b.U_User,b.U_Warning,b.U_Reject,b.U_Entry,
    TestFreq = 
 	 CASE 
          WHEN b.Test_Freq IS NOT NULL THEN b.Test_Freq
          ELSE a.DefTestFreq 
        END
  From @M650Vars a
  Left Outer Join Var_Specs b on (B.Var_Id = a.Var_Id) And (b.Prod_Id = @ProdId) And (b.Effective_Date <= @TimeStamp) And ((b.Expiration_Date > @TimeStamp) Or (b.Expiration_Date Is NULL))
  Order By a.Var_Id
