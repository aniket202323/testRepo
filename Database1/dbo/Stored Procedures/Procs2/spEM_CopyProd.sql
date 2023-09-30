CREATE PROCEDURE dbo.spEM_CopyProd
  @From_Prod_Id   int,
  @To_Prod_Id     int,
  @User_Id           int
  AS
DECLARE @Now       	 DateTime,
 	  	 @TransId 	 Int,
 	  	 @TransDesc 	 nvarchar(50)
--
--
Select @Now = dbo.fnServer_CmnGetDate(getUTCdate())
DECLARE @Insert_Id integer 
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CopyProd',
                convert(nVarChar(10),@From_Prod_Id) + ','  + Convert(nVarChar(10), @To_Prod_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
/* Product info Fixed while doing ECR #29022  */
Declare @Product_Change_Esignature_Level int,@Event_Esignature_Level Int,@Extended_Info nvarchar(255)
Select @Product_Change_Esignature_Level = Product_Change_Esignature_Level ,@Event_Esignature_Level = Event_Esignature_Level,@Extended_Info=Extended_Info
 	 From Products
 	 Where Prod_Id = @From_Prod_Id
Update Products set Product_Change_Esignature_Level = @Product_Change_Esignature_Level ,Event_Esignature_Level = @Event_Esignature_Level,Extended_Info=@Extended_Info
 	 Where Prod_Id = @To_Prod_Id
/* Default chars  ECR #29022  */ 
INsert Into Product_Characteristic_Defaults (Prod_Id,Char_Id,Prop_Id)
 	 Select @To_Prod_Id,Char_Id,Prop_Id
 	 From Product_Characteristic_Defaults
 	 Where Prod_Id = @From_Prod_Id
/* Product Group Data */
Insert Into Product_Group_Data (Product_Grp_Id,Prod_Id)
  Select Product_Grp_Id,@To_Prod_Id
 	 From Product_Group_Data Where Prod_Id = @From_Prod_Id
--/* Product X-Ref */
--Insert Into Prod_XRef (Prod_Id,PU_Id,Prod_Code_XRef)
-- 	 Select @To_Prod_Id,PU_Id,Prod_Code_XRef from Prod_XRef Where Prod_Id = @From_Prod_Id and pu_Id is not null
/* Path products */
Insert into PrdExec_Path_Products (Path_Id,Prod_Id)
 	 SELECT Path_Id,@To_Prod_Id
 	  From PrdExec_Path_Products 
 	  Where Prod_Id = @From_Prod_Id
/* Create Transaction */
Select @TransDesc = '<' + Prod_Code + '> '  + Convert(nVarChar(25),@Now,20)
    From Products 
 	 Where Prod_Id = @To_Prod_Id
Insert Into transactions (Trans_Create_Date,Trans_Type_Id,Transaction_Grp_Id,Trans_Desc)
 	 Values (@Now,1,1,@TransDesc)
Select @TransId = Scope_Identity()
/* PU Products */
Insert InTo Trans_Products (PU_Id,Prod_Id,Trans_Id,Is_Delete)
 	 Select PU_Id,@To_Prod_Id,@TransId,0
 	   From PU_Products 
 	   Where Prod_Id = @From_Prod_Id
/* PU Characteristics */
Insert into Trans_Characteristics (Prop_Id,Char_Id,Trans_Id,PU_Id,Prod_Id)
 	 SELECT Prop_Id,Char_Id,@TransId,PU_Id,@To_Prod_Id
 	  From PU_Characteristics 
 	  Where Prod_Id = @From_Prod_Id
/* Variable Specs */
Declare @Var_Id 	  	 Int,
 	  	 @L_Entry 	 nVarChar(25),
 	  	 @L_Reject 	 nVarChar(25),
 	  	 @L_Warning 	 nVarChar(25),
 	  	 @L_User 	  	 nVarChar(25),
 	  	 @Target 	  	 nVarChar(25),
 	  	 @U_User 	  	 nVarChar(25),
 	  	 @U_Warning 	 nVarChar(25),
 	  	 @U_Reject 	 nVarChar(25),
 	  	 @U_Entry 	 nVarChar(25),
 	  	 @L_Control 	 nVarChar(25),
 	  	 @T_Control 	 nVarChar(25),
 	  	 @U_Control 	 nVarChar(25),
 	  	 @Test_Freq 	 int,
 	  	 @Sig 	  	 Int
Declare CopyProdCursor cursor For 
   SELECT vs.Var_Id,L_Entry,L_Reject,L_Warning,L_User,Target,U_User,U_Warning,U_Reject,
           U_Entry,L_Control,T_Control,U_Control,Test_Freq,vs.Esignature_Level
        FROM Var_Specs vs
 	  	 Join Variables v on v.Var_Id =  vs.Var_Id and v.Spec_Id is null
        WHERE  (Prod_Id = @From_Prod_Id) AND
               ((Effective_Date <  @Now) and
               ((Expiration_Date IS NULL) or 
                (Expiration_Date > @Now)))
Open CopyProdCursor
SpecLoop:
Fetch Next From CopyProdCursor Into @Var_Id,@L_Entry,@L_Reject,@L_Warning,@L_User,@Target,@U_User,@U_Warning,@U_Reject,
 	  	  	  	  	 @U_Entry,@L_Control,@T_Control,@U_Control,@Test_Freq,@Sig
  If @@Fetch_Status = 0
 	 Begin
       Execute  spEM_PutTransVarValues @TransId,@Var_Id,@To_Prod_Id,@L_Entry,@L_Reject,@L_Warning,@L_User,@Target,
 	  	  	  	  	  	  	  	  	 @U_User,@U_Warning,@U_Reject,@U_Entry,@L_Control,@T_Control,@U_Control,@Test_Freq,@Sig,Null,Null,@User_Id
 	    Goto SpecLoop
 	 End
 	 Close CopyProdCursor
 	 Deallocate CopyProdCursor
 	 Execute SpEM_ApproveTrans @TransId,@User_Id,1,null,null,@Now
Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0 where Audit_Trail_Id = @Insert_Id
Return(0)
