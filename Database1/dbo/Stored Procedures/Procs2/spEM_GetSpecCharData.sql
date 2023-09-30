CREATE PROCEDURE dbo.spEM_GetSpecCharData
  @Var_Id int,
  @ProdIds nvarchar(1000),
  @Trans_Id int,
  @DecimalSep     nVarChar(2) = '.'
  AS
  --
  DECLARE @Now          DateTime,
 	 @MasterPU       int,
 	 @Prop_Id 	 int,
 	 @PUG_Id 	  	 int,
 	 @Char_Id 	 int,
 	 @Spec_Id 	 int,
 	 @PrevCharId 	 int,
 	 @Is_Defined 	 int,
 	 @Char_Counter  	 int,
 	 @DerivedFromP  	 int,
 	 @Prod_Id 	 int
  SELECT @Now = dbo.fnServer_CmnGetDate(getUTCdate())
  SELECT @PUG_Id = v.PUG_Id,@Prop_Id = s.Prop_Id, @Spec_Id = v.Spec_Id
       FROM Variables v
       JOIN Specifications s ON s.Spec_Id = v.Spec_Id
       WHERE v.Var_Id = @Var_Id
  SELECT @MasterPU = (SELECT Master_Unit FROM Prod_Units WHERE PU_Id = (SELECT PU_Id FROM PU_Groups where PUG_Id = @PUG_Id))
  IF @MasterPU IS NULL  Select @MasterPU = (SELECT PU_Id FROM PU_Groups where PUG_Id = @PUG_Id)
  Create Table #Prods (Prod_Id Int)
  Create Table #Path (Spec_Id Integer,Char_Id Integer,UE_Path nvarchar(255),UR_Path nvarchar(255),UW_Path nvarchar(255),
 	  	  	 UU_Path nvarchar(255),T_Path nvarchar(255),LU_Path nvarchar(255),
 	  	  	 LW_Path nvarchar(255),LR_Path nvarchar(255),LE_Path nvarchar(255),LC_Path nvarchar(255),TC_Path nvarchar(255),UC_Path nvarchar(255),
 	  	  	 TF_Path nvarchar(255),SIG_Path nvarchar(255))
  Create Table #CharIds(Char_Id integer,Char_Counter Integer)
  Create Table #TransProp( Spec_Id 	 int,
 	  	  	 Char_Id 	  	 int,
 	  	  	 L_Entry 	  	 nvarchar(25),
 	  	  	 L_Reject 	 nvarchar(25),
 	  	  	 L_Warning 	 nvarchar(25),
 	  	  	 L_User 	  	 nvarchar(25),
 	  	  	 Target 	  	 nvarchar(25),
 	  	  	 U_User 	  	 nvarchar(25),
 	  	  	 U_Warning 	 nvarchar(25),
 	  	  	 U_Reject 	 nvarchar(25),
 	  	  	 U_Entry 	  	 nvarchar(25),
 	  	  	 L_Control 	 nvarchar(25),
 	  	  	 T_Control 	 nvarchar(25),
 	  	  	 U_Control 	 nvarchar(25),
 	  	  	 Test_Freq 	 int,
 	  	  	 Esignature_Level 	 int,
 	  	  	 Comment_Id  int,
 	  	  	 Expiration_Date DateTime,
 	  	  	 Is_Defined 	 Int,
 	  	  	 Not_Defined 	 Int)
-- Populate Products
  SELECT Spec_Id FROM Specifications WHERE Prop_Id = @Prop_Id
While (LEN( LTRIM(RTRIM(@ProdIds))) > 1) 
  Begin
       Insert into #Prods (prod_id) Values (Convert(Int,SubString(@ProdIds,1,CharIndex(Char(1),@ProdIds)-1)))
       Select @ProdIds = SubString(@ProdIds,CharIndex(Char(1),@ProdIds),LEN(@ProdIds))
       Select @ProdIds = Right(@ProdIds,LEN(@ProdIds)-1)
  End
Execute( 'Declare p Cursor Global For Select Prod_Id From #Prods For Read Only')
open p
pLoop:
Fetch next from p into @Prod_Id
If @@Fetch_Status = 0 
 Begin  
  SELECT @Char_Id = Char_Id FROM PU_Characteristics WHERE
    PU_Id = @MasterPU AND Prod_Id = @Prod_Id AND Prop_Id = @Prop_Id
--
-- Process transaction
--
 Select @Char_Id = Coalesce(Char_Id,@Char_Id)
   From Trans_Characteristics
   Where   PU_Id = @MasterPU AND Prod_Id = @Prod_Id AND Prop_Id = @Prop_Id And Trans_Id = @Trans_Id
  --
Insert Into #Path (Spec_Id ,Char_Id)
 	 Select s.Spec_Id, c.Char_Id
 	     FROM Characteristics c,Specifications s
     WHERE c.Char_Id = @Char_Id  and s.Prop_Id = @Prop_Id
Insert Into #CharIds(Char_Id,Char_Counter) Values(@Char_Id,1)
Select @PrevCharId = @Char_Id
Select @Char_Counter = 2
Loop:
  Select @PrevCharId = Null
  Select @PrevCharId = Derived_From_Parent
      From Characteristics
      Where Char_Id = @Char_Id
  Select @PrevCharId = Coalesce(To_Char_Id,@PrevCharId) From Trans_Char_Links Where From_Char_Id = @Char_Id and  Trans_Id = @Trans_Id
  If @PrevCharId is not null
 	 Begin
 	   Insert Into #CharIds  (Char_Id,Char_Counter) Values(@PrevCharId,@Char_Counter)
 	   Select @Char_Id = @PrevCharId,@Char_Counter = @Char_Counter + 1
 	   Goto Loop
 	 End
 Execute( 'Declare Char_Cursor  Cursor Global ' +
'For Select Char_Id From #CharIds Order by Char_Counter Desc ' +
'For Read Only')
Open  Char_Cursor
FetchNextChar:
Fetch Next From Char_Cursor into @Char_Id
IF @@Fetch_Status = 0
 	 Begin
 	    Execute( 'Declare Spec_Cursor   Cursor Global ' +   
 	    'For Select Spec_Id From #Path ' +
 	    'For update')  --
 	    Open Spec_Cursor
 	    FetchNextSpec:
 	    Fetch Next From Spec_Cursor into @Spec_Id
 	     IF @@Fetch_Status = 0
 	  	 Begin
 	  	   Select @Is_Defined = null, @DerivedFromP = Null
 	  	   Select @DerivedFromP = Derived_From_Parent From Characteristics Where  Char_Id = @Char_Id
 	  	   Select @DerivedFromP = Coalesce( To_Char_Id,@DerivedFromP) From Trans_Char_Links Where  From_Char_Id = @Char_Id and Trans_Id = @Trans_Id
--
-- |  = Defined Here 
-- *| = Not Defined yet
-- || = Defined at a higher level and overridden here
--
 	  	   Select @Is_Defined = Is_Defined
 	  	  	 From active_Specs 
 	  	  	 Where Spec_Id = @Spec_Id And Char_Id = @Char_Id And (Effective_Date <= @Now) AND  ((Expiration_Date IS NULL) OR ((Expiration_Date IS NOT NULL) AND (Expiration_Date > @Now)))
-- 	  	   select @Spec_Id,@Is_Defined,T_Path From #Path
 	  	   Update #Path set TF_Path =   CASE 
                        WHEN @Is_Defined IS NULL And TF_Path IS NOT NULL Then TF_Path + convert(nVarChar(10),@Char_Id)  + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 512 = 0 And TF_Path IS NOT NULL then TF_Path + convert(nVarChar(10),@Char_Id) + '|' 
 	  	  	  	  	  	 When  @Is_Defined & 512 =  512  and TF_Path IS NULL Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 512 =  512  and Substring(TF_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END,
  	  	  	  	    Sig_Path =   CASE 
                        WHEN  @Is_Defined IS NULL And Sig_Path IS NOT NULL Then Sig_Path + convert(nVarChar(10),@Char_Id)  + '|'
 	  	  	  	  	  	 WHEN  @Is_Defined & 1024 = 0 And Sig_Path IS NOT NULL then Sig_Path + convert(nVarChar(10),@Char_Id) + '|' 
 	  	  	  	  	  	 When  @Is_Defined & 1024 =  1024  and Sig_Path IS NULL Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 1024 =  1024  and Substring(Sig_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END,
 	  	  	  	    UE_Path =   CASE 
                          	  	  	  	  	 WHEN @Is_Defined IS NULL And UE_Path IS NOT NULL Then UE_Path  + convert(nVarChar(10),@Char_Id) + '|' 
 	  	  	  	  	  	 WHEN @Is_Defined & 256 <> 256 And UE_Path IS NOT NULL Then UE_Path + convert(nVarChar(10),@Char_Id)  + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 256 = 256 And UE_Path IS NULL Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 256 =  256  and Substring(UE_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END,
 	  	  	  	    UR_Path =   CASE 
                          	  	  	  	  	 WHEN @Is_Defined IS NULL And UR_Path IS NOT NULL Then UR_Path  +  convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 128 <> 128 And UR_Path IS NOT NULL Then UR_Path +  convert(nVarChar(10),@Char_Id) + '|' 
 	  	  	  	  	  	 WHEN @Is_Defined & 128 = 128 And UR_Path IS NULL Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 128 =  128  and Substring(UR_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END,
 	  	  	  	    UW_Path =   CASE 
                          	  	  	  	  	 WHEN @Is_Defined IS NULL And UW_Path IS NOT NULL Then UW_Path  +  convert(nVarChar(10),@Char_Id)  + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 64 <> 64 And UW_Path IS NOT NULL Then UW_Path +  convert(nVarChar(10),@Char_Id)  + '|' 
 	  	  	  	  	  	 WHEN @Is_Defined & 64 = 64 And UW_Path IS NULL Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 64 =  64  and Substring(UW_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END,
 	  	  	  	    UU_Path =   CASE 
                          	  	  	  	  	 WHEN @Is_Defined IS NULL And UU_Path IS NOT NULL Then UU_Path  +  convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 32 <> 32  And UU_Path IS NOT NULL Then UU_Path  + convert(nVarChar(10),@Char_Id)+ '|' 
 	  	  	  	  	  	 WHEN @Is_Defined & 32 = 32 And UU_Path IS NULL Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 32 =  32  and Substring(UU_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END,
 	  	                    	  T_Path =    CASE 
                          	  	  	  	  	 WHEN @Is_Defined IS NULL And T_Path IS NOT NULL Then T_Path  + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 16 <> 16 And T_Path IS NOT NULL Then T_Path  +  convert(nVarChar(10),@Char_Id) + '|' 
 	  	  	  	  	  	 WHEN @Is_Defined & 16 = 16 And T_Path IS NULL Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 16 =  16  and Substring(T_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END, 	  	  
 	  	  	  	    LU_Path =   CASE
                          	  	  	  	  	 WHEN @Is_Defined IS NULL And LU_Path IS NOT NULL Then LU_Path +   convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 8 = 0 And LU_Path IS NOT NULL Then LU_Path  +  convert(nVarChar(10),@Char_Id)  + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 8 = 8 And LU_Path IS NULL Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 8 =  8  and Substring(LU_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END,
 	  	  	  	    LW_Path =   CASE 
                          	  	  	  	  	 WHEN @Is_Defined IS NULL And LW_Path IS NOT NULL Then LW_Path +  convert(nVarChar(10),@Char_Id) + '|' 
 	  	  	  	  	  	 WHEN @Is_Defined & 4 <> 4 And LW_Path IS NOT NULL Then LW_Path  +  convert(nVarChar(10),@Char_Id) + '|' 
 	  	  	  	  	  	 WHEN @Is_Defined & 4 = 4 And LW_Path IS NULL Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 4 =  4  and Substring(LW_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END,
 	  	  	  	    LR_Path =   CASE 
                        WHEN @Is_Defined IS NULL And LR_Path IS NOT NULL Then LR_Path  +  convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 2 <> 2  And LR_Path IS NOT NULL Then LR_Path  +  convert(nVarChar(10),@Char_Id)  + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 2 = 2 And LR_Path IS NULL Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 2 =  2  and Substring(LR_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END,
 	  	  	  	    LE_Path =   CASE 
                        WHEN @Is_Defined IS NULL And LE_Path IS NOT NULL Then LE_Path  +  convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 1 <> 1 And LE_Path IS NOT NULL Then LE_Path + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 1 = 1 And LE_Path IS NULL Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 1 =  1  and Substring(LE_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END,
 	  	  	  	    LC_Path =   CASE 
                        WHEN @Is_Defined IS NULL And LC_Path IS NOT NULL Then LC_Path  +  convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 8192 <> 8192 And LC_Path IS NOT NULL Then LC_Path + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 8192 = 8192 And LC_Path IS NULL Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 8192 =  8192  and Substring(LC_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END,
 	  	  	  	    TC_Path =   CASE 
                        WHEN @Is_Defined IS NULL And TC_Path IS NOT NULL Then TC_Path  +  convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 16384 <> 16384 And TC_Path IS NOT NULL Then TC_Path + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 16384 = 16384 And TC_Path IS NULL Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 16384 =  16384  and Substring(TC_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END,
 	  	  	  	    UC_Path =   CASE 
                        WHEN @Is_Defined IS NULL And UC_Path IS NOT NULL Then UC_Path  +  convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 32768 <> 32768 And UC_Path IS NOT NULL Then UC_Path + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 32768 = 32768 And UC_Path IS NULL Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 32768 =  32768  and Substring(UC_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END
 	  	    where current of Spec_Cursor
 	      	   GoTo FetchNextSpec
 	  	 End
 	     close Spec_Cursor
 	     Deallocate Spec_Cursor
 	     Goto FetchNextChar
 	 End
 	 Close Char_Cursor
 	 Deallocate Char_Cursor
Delete From #CHARIDS
Update #Path set TF_Path =   CASE 
 	  	  	  	 When  Substring( TF_Path ,1,1) = '*' Then Substring( TF_Path ,2,datalength( TF_Path ))
 	  	  	  	 Else TF_Path
             	  	  	         END,
 	  	 Sig_Path =   CASE 
 	  	  	  	 When  Substring( Sig_Path ,1,1) = '*' Then Substring( Sig_Path ,2,datalength( Sig_Path ))
 	  	  	  	 Else Sig_Path
             	  	  	         END,
 	  	 UE_Path =   CASE 
 	  	  	  	 When  Substring( UE_Path ,1,1) = '*' Then Substring( UE_Path ,2,datalength( UE_Path ))
 	  	  	  	 Else UE_Path
             	  	  	         END,
 	  	 UR_Path =   CASE 
 	  	  	  	 When  Substring( UR_Path ,1,1) = '*' Then Substring( UR_Path ,2,datalength( UR_Path ))
 	  	  	  	 Else UR_Path
             	  	  	         END,
 	  	 UW_Path =   CASE 
 	  	  	  	 When  Substring( UW_Path ,1,1) = '*' Then Substring( UW_Path ,2,datalength( UW_Path ))
 	  	  	  	 Else UW_Path
             	  	  	         END,
 	  	 UU_Path =   CASE 
 	  	  	  	 When  Substring( UU_Path ,1,1) = '*' Then Substring( UU_Path ,2,datalength( UU_Path ))
 	  	  	  	 Else UU_Path
             	  	  	         END,
 	  	 T_Path =    CASE 
 	  	  	  	 When  Substring( T_Path ,1,1) = '*' Then Substring( T_Path ,2,datalength( T_Path ))
 	  	  	  	 Else T_Path
             	  	  	         END,
 	  	 LU_Path =   CASE
 	  	  	  	 When  Substring( LU_Path ,1,1) = '*' Then Substring( LU_Path ,2,datalength( LU_Path ))
 	  	  	  	 Else LU_Path
             	  	  	         END,
 	  	 LW_Path =   CASE 
 	  	  	  	 When  Substring( LW_Path ,1,1) = '*' Then Substring( LW_Path ,2,datalength( LW_Path ))
 	  	  	  	 Else LW_Path
             	  	  	         END,
 	  	 LR_Path =   CASE 
 	  	  	  	 When  Substring( LR_Path ,1,1) = '*' Then Substring( LR_Path ,2,datalength( LR_Path ))
 	  	  	  	 Else LR_Path
             	  	  	         END,
 	  	 LE_Path =   CASE 
 	  	  	  	 When  Substring( LE_Path ,1,1) = '*' Then Substring( LE_Path ,2,datalength( LE_Path ))
 	  	  	  	 Else LE_Path
             	  	  	         END,
 	  	 LC_Path =   CASE 
 	  	  	  	 When  Substring( LC_Path ,1,1) = '*' Then Substring( LC_Path ,2,datalength( LC_Path ))
 	  	  	  	 Else LC_Path
             	  	  	         END,
 	  	 TC_Path =   CASE 
 	  	  	  	 When  Substring( TC_Path ,1,1) = '*' Then Substring( TC_Path ,2,datalength( TC_Path ))
 	  	  	  	 Else TC_Path
             	  	  	         END,
 	  	 UC_Path =   CASE 
 	  	  	  	 When  Substring( UC_Path ,1,1) = '*' Then Substring( UC_Path ,2,datalength( UC_Path ))
 	  	  	  	 Else UC_Path
             	  	  	         END
  SELECT s.Spec_Id,
         C.Char_Id,
         U_Entry = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.U_Entry, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.U_Entry
 	  	  	  	  	  	 End,
         U_Reject = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.U_Reject, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.U_Reject
 	  	  	  	  	  	 End,
         U_Warning = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.U_Warning, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.U_Warning
 	  	  	  	  	  	 End,
         U_User = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.U_User, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.U_User
 	  	  	  	  	  	 End,
         Target = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.Target, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.Target
 	  	  	  	  	  	 End,
         L_User = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.L_User, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.L_User
 	  	  	  	  	  	 End,
         L_Warning = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.L_Warning, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.L_Warning
 	  	  	  	  	  	 End,
         L_Reject = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.L_Reject, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.L_Reject
 	  	  	  	  	  	 End,
         L_Entry = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.L_Entry, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.L_Entry
 	  	  	  	  	  	 End,
         L_Control = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.L_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.L_Control
 	  	  	  	  	  	 End,
         T_Control = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.T_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.T_Control
 	  	  	  	  	  	 End,
         U_Control = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(a.U_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else a.U_Control
 	  	  	  	  	  	 End,
         a.Test_Freq,
         a.Esignature_Level,
         a.Comment_Id,
         a.Expiration_Date,
         a.Is_Defined,
         UE_Path,
         UR_Path,
         UW_Path,
         UU_Path,
         T_Path,
         LU_Path,
         LW_Path,
         LR_Path,
         LE_Path,
         LC_Path,
         TC_Path,
         UC_Path,
         TF_Path, 
         Sig_Path 
    FROM Characteristics c, Specifications s
    LEFT JOIN Active_Specs a ON (s.Spec_Id = a.Spec_Id) and (a.Char_Id = @Char_Id)  AND (Effective_Date <= @Now) AND
          ((Expiration_Date IS NULL) OR ((Expiration_Date IS NOT NULL) AND (Expiration_Date > @Now)))
    LEFT Join #Path p On p.Spec_Id = s.Spec_Id and p.Char_Id = @Char_Id
     WHERE c.Char_Id = @Char_Id  and (s.Prop_Id = @Prop_Id)
Insert into #TransProp Execute spEM_TransPPExpand  @Trans_Id,@Char_Id,1
  SELECT t.Spec_Id,
         t.Char_Id,
         U_Entry = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.U_Entry, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.U_Entry
 	  	  	  	  	  	 End,
         U_Reject = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.U_Reject, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.U_Reject
 	  	  	  	  	  	 End,
         U_Warning = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.U_Warning, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.U_Warning
 	  	  	  	  	  	 End,
         U_User = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.U_User, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.U_User
 	  	  	  	  	  	 End,
         Target = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.Target, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.Target
 	  	  	  	  	  	 End,
         L_User = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.L_User, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.L_User
 	  	  	  	  	  	 End,
         L_Warning = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.L_Warning, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.L_Warning
 	  	  	  	  	  	 End,
         L_Reject = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.L_Reject, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.L_Reject
 	  	  	  	  	  	 End,
         L_Entry = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.L_Entry, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.L_Entry
 	  	  	  	  	  	 End,
         L_Control = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.L_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.L_Control
 	  	  	  	  	  	 End,
         T_Control = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.T_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.T_Control
 	  	  	  	  	  	 End,
         U_Control = Case When s.Data_Type_Id = 2 and @DecimalSep != '.' Then  REPLACE(t.U_Control, '.', @DecimalSep)
 	  	  	  	  	  	 Else t.U_Control
 	  	  	  	  	  	 End,
         t.Test_Freq,
 	  	  t.Esignature_Level,
         t.Comment_Id,
         t.Expiration_Date,
         t.Is_Defined,
         t.Not_Defined,
         UE_Path,
         UR_Path,
         UW_Path,
         UU_Path,
         T_Path,
         LU_Path,
         LW_Path,
         LR_Path,
         LE_Path,
         LC_Path,
         TC_Path,
         UC_Path,
         TF_Path, 
         Sig_Path 
    FROM #TransProp t
    Left JOIN Characteristics c ON (c.Prop_Id = @Prop_Id) AND (c.Char_Id = t.Char_Id)
    Left  JOIN Specifications s ON (s.Prop_Id = @Prop_Id) AND (s.Spec_Id = t.Spec_Id) AND (t.Char_Id = @Char_Id)
    LEFT Join #Path p On p.Spec_Id = s.Spec_Id and p.Char_Id = @Char_Id
    WHERE t.Char_Id = @Char_Id
    Delete From #Path
    Delete From #TransProp
    goto pLoop
end
drop table #Path
drop table #TransProp
DROP TABLE #CHARIDS
