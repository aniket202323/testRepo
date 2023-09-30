CREATE PROCEDURE dbo.spServer_EMgrGet0097Specs
@TimeStamp datetime
 AS
Declare
  @@PU_Id int,
  @@Var_Id int,
  @@PropId int,
  @@Prod_Id int,
  @U_Entry nVarChar(25),
  @U_Reject nVarChar(25),
  @Target nVarChar(25),
  @L_Reject nVarChar(25),
  @L_Entry nVarChar(25),
  @ProdCode nVarChar(25),
  @Num int,
  @EDModelId int
Declare @AutolineVars Table(PU_Id int, Var_Id int, PropId int null, Input_Tag nVarChar(100) COLLATE DATABASE_DEFAULT null)
Declare @Results Table(ProdCode nvarchar(25) COLLATE DATABASE_DEFAULT , PropId int, U_Entry nvarchar(25) COLLATE DATABASE_DEFAULT NULL, U_Reject nvarchar(25) COLLATE DATABASE_DEFAULT NULL, Target nvarchar(25) COLLATE DATABASE_DEFAULT NULL, L_Reject nvarchar(25) COLLATE DATABASE_DEFAULT NULL, L_Entry nvarchar(25) COLLATE DATABASE_DEFAULT NULL)
Select @EDModelId = NULL
Select @EDModelId = ED_Model_Id From ED_Models Where Model_Num = 93
Insert Into @AutolineVars (PU_Id, Var_Id,Input_Tag) (Select PU_Id,Var_Id,Upper(Input_Tag) From Variables_Base Where (DS_Id = 14) And (Input_Tag Like '%\V1%') And (PU_Id Not In (Select PU_Id From Event_Configuration Where (ED_Model_Id = @EDModelId) And (Is_Active = 1))))
Update @AutolineVars Set Input_Tag = SubString(Input_Tag,CharIndex('\',Input_Tag) + 1,100)
Delete From @AutolineVars Where (Input_Tag Is NULL) Or (CharIndex('\',Input_Tag) = 0)
Delete From @AutolineVars Where SubString(Input_Tag,CharIndex('\',Input_Tag) + 1,100) > 'V1'
Update @AutolineVars Set Input_Tag = SubString(Input_Tag,1,CharIndex('\',Input_Tag) - 1)
Delete From @AutolineVars Where (Input_Tag Is NULL)
Update @AutolineVars Set PropId = Convert(int,Input_Tag)
Select @Num = NULL
Select @Num = Count(VS_Id) 
  From Var_Specs 
  Where (Effective_Date >= @TimeStamp) And 
        (Expiration_Date Is NULL) And 
        (Var_Id In (Select Var_Id From @AutolineVars))
If (@Num = 0) Or (@Num Is NULL)
  Goto TheEnd
Declare Var_Cursor INSENSITIVE CURSOR 
  For (Select PU_Id,Var_Id,PropId From @AutolineVars)
  For Read Only
Open Var_Cursor  
Fetch_Loop:
  Fetch Next From Var_Cursor Into @@PU_Id,@@Var_Id,@@PropId
  If (@@Fetch_Status = 0)
    Begin
      Declare Prod_Cursor INSENSITIVE CURSOR
        For (Select Prod_Id From PU_Products Where PU_Id = @@PU_Id)
        For Read Only
        Open Prod_Cursor   
      Product_Loop:
        Fetch Next From Prod_Cursor Into @@Prod_Id
        If (@@Fetch_Status = 0)
          Begin
            Select @ProdCode = Prod_Code From Products Where Prod_Id = @@Prod_Id
            Select @U_Entry = NULL
            Select @U_Reject = NULL
            Select @Target = NULL
            Select @L_Reject = NULL
            Select @L_Entry = NULL
            Select @U_Entry = U_Entry,
                   @U_Reject = U_Reject,
                   @Target = Target,
                   @L_Reject = L_Reject,
                   @L_Entry = L_Entry
              From Var_Specs
              Where (Prod_Id = @@Prod_Id) And
                    (Var_Id = @@Var_Id) And 
                    (Expiration_Date Is NULL)
            Insert Into @Results (ProdCode,PropId,U_Entry,U_Reject,Target,L_Reject,L_Entry)
              Values(@ProdCode,@@PropId,@U_Entry,@U_Reject,@Target,@L_Reject,@L_Entry)
            Goto Product_Loop
          End
      Close Prod_Cursor
      Deallocate Prod_Cursor
      Goto Fetch_Loop
    End
Close Var_Cursor
Deallocate Var_Cursor
TheEnd:
Select  	 ProdCode = ProdCode,
 	 PropId = PropId,
 	 UEntry = COALESCE(U_Entry,''),
 	 UReject = COALESCE(U_Reject,''),
 	 Target = COALESCE(Target,''),
 	 LReject = COALESCE(L_Reject,''),
 	 LEntry = COALESCE(L_Entry,''),
 	 Unused1 = 10,
 	 Unused2 = 12
  From @Results
  Order By ProdCode,PropId
