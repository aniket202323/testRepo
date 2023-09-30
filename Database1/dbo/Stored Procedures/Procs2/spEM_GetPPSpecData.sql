CREATE PROCEDURE dbo.spEM_GetPPSpecData
  @Char_Id int,
  @Trans_Id int,
  @DecimalSep     nVarChar(2) = '.'
  AS
  --
  DECLARE @Now          Datetime,
 	 @MasterPU        int,
 	 @Prop_Id 	 int,
 	 @PUG_Id 	 int,
 	 @Spec_Id 	 int,
 	 @PrevCharId 	 int,
 	 @Is_Defined 	 int,
 	 @Is_Defined2 	 int,
 	 @Not_Defined 	 Int,
 	 @Char_Counter int,
 	 @DerivedFromP int,
 	 @SqlStmt  	 nvarchar(255),
 	 @TransCount 	 Int
  SELECT @Now = dbo.fnServer_CmnGetDate(getUTCdate())
  SELECT @Prop_Id = Prop_Id
       FROM Characteristics
       WHERE Char_Id = @Char_Id
  Create Table #TransPP(   Spec_Id 	 int,
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
 	  	  	 Comment_Id 	 int,
 	  	  	 Expiration_date  DateTime,
 	  	  	 Is_Defined 	 Int,
 	  	  	 Not_Defined 	 Int)
   If (select count(*) From Trans_Char_links Where trans_id = @Trans_Id) <> 0 or    (select count(*) From Trans_Properties Where trans_id = @Trans_Id) <> 0 
 	 Insert into  #TransPP  Execute spEM_TransPPExpand  @Trans_Id,@Char_Id,1
Create Table #Path (Spec_Id Integer,Char_Id Integer,UE_Path nvarchar(255) null ,UR_Path nvarchar(255) null ,UW_Path nvarchar(255) null,
 	  	  	 UU_Path nvarchar(255) null,T_Path nvarchar(255) null ,LU_Path nvarchar(255) null ,
 	  	  	 LW_Path nvarchar(255) null, LR_Path nvarchar(255) null , LE_Path nvarchar(255) null , TF_Path nvarchar(255) null,SIG_Path nvarchar(255) null, LC_Path nvarchar(255) null, TC_Path nvarchar(255) null, UC_Path nvarchar(255) null )
create  index Path1 on #Path (char_Id)
create  index Path2 on #Path (spec_Id)
Insert InTo #Path (Spec_Id ,Char_Id)
 	 Select s.Spec_Id, c.Char_Id
 	     FROM Characteristics c,Specifications s
     WHERE c.Char_Id = @Char_Id  and (s.Prop_Id = @Prop_Id)
Create Table #CharIds(Char_Id integer,Char_Counter Integer)
Insert Into #CharIds(Char_Id,Char_Counter) Values(@Char_Id,1)
Select @Char_Counter = 2
Loop:
  Select @PrevCharId = null
  Select @PrevCharId = To_Char_Id From Trans_Char_Links Where From_Char_Id =  @Char_Id and Trans_Id = @Trans_Id 
  If @PrevCharId is null
       Select @PrevCharId = Derived_From_Parent from Characteristics Where Char_Id = @Char_Id 
  If @PrevCharId is not null
 	 Begin
 	   Insert Into #CharIds  (Char_Id,Char_Counter) Values(@PrevCharId,@Char_Counter)
 	   Select @Char_Id = @PrevCharId,@Char_Counter = @Char_Counter + 1
 	   Goto Loop
 	 End
Execute( 'Declare Char_Cursor  Cursor Global ' +
'For Select Char_Id From #CharIds order by Char_Counter Desc ' +
'For Read Only')
Open  Char_Cursor
FetchNextChar:
Fetch Next From Char_Cursor into @Char_Id
IF @@Fetch_Status = 0
 	 Begin
 	    Execute( 'Declare Spec_Cursor   Cursor Global ' +
 	    'For Select Spec_Id From #Path ' +
 	    'For update')  
 	    Open Spec_Cursor
 	    FetchNextSpec:
 	    Fetch Next From Spec_Cursor into @Spec_Id
 	     IF @@Fetch_Status = 0
 	  	 Begin
 	  	   Select @Is_Defined = null, @DerivedFromP = Null
 	  	   Select @DerivedFromP = Char_Id From #CharIds Where Char_Id =  @Char_Id and Char_Counter <> @Char_Counter -1  	  	 
 	  	   If @DerivedFromP is null
 	  	     Select @DerivedFromP = Derived_From_Parent From Characteristics Where  Char_Id = @Char_Id
--
-- |  = Defined Here 
-- *| = Not Defined yet
-- || = Definde at a higher level and overridden here
--
 	  	   Select @Is_Defined2 = Null,@Not_Defined = Null
 	  	   Select @Is_Defined2 = Is_Defined ,@Not_Defined = Not_Defined
 	  	  	 From Trans_Properties 
 	  	  	 Where Spec_Id = @Spec_Id And Char_Id = @Char_Id and Trans_Id = @Trans_Id
 	  	   Select @Is_Defined =   Is_Defined
 	  	  	 From active_Specs 
 	  	  	 Where Spec_Id = @Spec_Id And Char_Id = @Char_Id And (Effective_Date <= @Now) AND
 	  	           ((Expiration_Date IS NULL) OR ((Expiration_Date IS NOT NULL) AND (Expiration_Date > @Now)))
  	  	   Select @Is_Defined =   CASE
 	        	  	  	  	 When @Is_Defined2 Is Null and @Not_Defined  is null Then @Is_Defined
 	  	  	  	  	  	 When @Is_Defined Is Null Then @Is_Defined2
 	  	  	             When  @Not_Defined  is Not Null and  @Is_Defined2  is not null  Then ((@Is_Defined + @Is_Defined2) -  (@Is_Defined & @Is_Defined2)) - @Not_Defined 
 	  	  	  	        	 When  @Not_Defined  is Not Null then @Is_Defined - @Not_Defined 
 	  	  	             Else (@Is_Defined + @Is_Defined2) -  (@Is_Defined & @Is_Defined2)
 	  	  	  	             END
 	  	    	  	 Update #Path set TF_Path =   CASE 
                          	  	  	  	  	 WHEN @Is_Defined IS NULL And TF_Path IS NOT NULL Then TF_Path + convert(nVarChar(10),@Char_Id)  + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 512 = 0 And TF_Path IS NOT NULL then TF_Path + convert(nVarChar(10),@Char_Id) + '|' 
 	  	  	  	  	  	 When @Is_Defined & 512 =  512  and TF_Path IS NULL Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 512 =  512  and Substring(TF_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @DerivedFromP is null and TF_Path is null Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END,
 	  	    	  	    SIG_Path =   CASE 
                        WHEN @Is_Defined IS NULL And SIG_Path IS NOT NULL Then SIG_Path + convert(nVarChar(10),@Char_Id)  + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 1024 = 0 And SIG_Path IS NOT NULL then SIG_Path + convert(nVarChar(10),@Char_Id) + '|' 
 	  	  	  	  	  	 When @Is_Defined & 1024 =  1024  and SIG_Path IS NULL Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 1024 =  1024  and Substring(SIG_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @DerivedFromP is null and SIG_Path is null Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END,
 	  	  	  	    UE_Path =   CASE 
                          	  	  	  	  	 WHEN @Is_Defined IS NULL And UE_Path IS NOT NULL Then UE_Path  + convert(nVarChar(10),@Char_Id) + '|' 
 	  	  	  	  	  	 WHEN @Is_Defined & 256 <> 256 And UE_Path IS NOT NULL Then UE_Path + convert(nVarChar(10),@Char_Id)  + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 256 = 256 And UE_Path IS NULL Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 256 =  256  and Substring(UE_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @DerivedFromP is null and UE_Path is null Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END,
 	  	  	  	    UR_Path =   CASE 
                          	  	  	  	  	 WHEN @Is_Defined IS NULL And UR_Path IS NOT NULL Then UR_Path  +  convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 128 <> 128 And UR_Path IS NOT NULL Then UR_Path +  convert(nVarChar(10),@Char_Id) + '|' 
 	  	  	  	  	  	 WHEN @Is_Defined & 128 = 128 And UR_Path IS NULL Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 128 =  128  and Substring(UR_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @DerivedFromP is null and UR_Path is null Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END,
 	  	  	  	    UW_Path =   CASE 
                          	  	  	  	  	 WHEN @Is_Defined IS NULL And UW_Path IS NOT NULL Then UW_Path  +  convert(nVarChar(10),@Char_Id)  + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 64 <> 64 And UW_Path IS NOT NULL Then UW_Path +  convert(nVarChar(10),@Char_Id)  + '|' 
 	  	  	  	  	  	 WHEN @Is_Defined & 64 = 64 And UW_Path IS NULL Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 64 =  64  and Substring(UW_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @DerivedFromP is null and UW_Path is null Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END,
 	  	  	  	    UU_Path =   CASE 
                        WHEN @Is_Defined IS NULL And UU_Path IS NOT NULL Then UU_Path  +  convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 32 <> 32  And UU_Path IS NOT NULL Then UU_Path  + convert(nVarChar(10),@Char_Id)+ '|' 
 	  	  	  	  	  	 WHEN @Is_Defined & 32 = 32 And UU_Path IS NULL Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @Is_Defined & 32 = 32  and Substring(UU_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @DerivedFromP is null and UU_Path is null Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END,
 	  	            T_Path =    CASE 
                        WHEN @Is_Defined IS NULL And T_Path IS NOT NULL Then T_Path  + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 16 <> 16 And T_Path IS NOT NULL Then T_Path  +  convert(nVarChar(10),@Char_Id) + '|' 
 	  	  	  	  	  	 WHEN @Is_Defined & 16 = 16 And T_Path IS NULL Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 16 = 16  and Substring(T_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @DerivedFromP is null and T_Path is null Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END, 	  	  
 	  	  	  	    LU_Path =   CASE
                        WHEN @Is_Defined IS NULL And LU_Path IS NOT NULL Then LU_Path +   convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 8 = 0 And LU_Path IS NOT NULL Then LU_Path  +  convert(nVarChar(10),@Char_Id)  + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 8 = 8 And LU_Path IS NULL Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 8 =  8  and Substring(LU_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @DerivedFromP is null and LU_Path is null Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END,
 	  	  	  	    LW_Path =   CASE 
                        WHEN @Is_Defined IS NULL And LW_Path IS NOT NULL Then LW_Path +  convert(nVarChar(10),@Char_Id) + '|' 
 	  	  	  	  	  	 WHEN @Is_Defined & 4 <> 4 And LW_Path IS NOT NULL Then LW_Path  +  convert(nVarChar(10),@Char_Id) + '|' 
 	  	  	  	  	  	 WHEN @Is_Defined & 4 = 4 And LW_Path IS NULL Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 4 =  4  and Substring(LW_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @DerivedFromP is null and LW_Path is null Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END,
 	  	  	  	    LR_Path =   CASE 
                        WHEN @Is_Defined IS NULL And LR_Path IS NOT NULL Then LR_Path  +  convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 2 <> 2  And LR_Path IS NOT NULL Then LR_Path  +  convert(nVarChar(10),@Char_Id)  + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 2 = 2 And LR_Path IS NULL Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 2 =  2  and Substring(LR_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @DerivedFromP is null and LR_Path is null Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END,
 	  	  	  	    LE_Path =   CASE 
                        WHEN @Is_Defined IS NULL And LE_Path IS NOT NULL Then LE_Path  +  convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 1 <> 1 And LE_Path IS NOT NULL Then LE_Path + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 1 = 1 And LE_Path IS NULL Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 1 =  1  and Substring(LE_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @DerivedFromP is null and LE_Path is null Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END,
 	  	  	  	    LC_Path =   CASE 
                        WHEN @Is_Defined IS NULL And LC_Path IS NOT NULL Then LC_Path  +  convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 8192 <> 8192 And LC_Path IS NOT NULL Then LC_Path + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 8192 = 8192 And LC_Path IS NULL Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 8192 =  8192  and Substring(LC_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @DerivedFromP is null and LC_Path is null Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END,
 	  	  	  	    TC_Path =   CASE 
                        WHEN @Is_Defined IS NULL And TC_Path IS NOT NULL Then TC_Path  +  convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 16384 <> 16384 And TC_Path IS NOT NULL Then TC_Path + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 16384 = 16384 And TC_Path IS NULL Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 16384 =  16384  and Substring(TC_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @DerivedFromP is null and TC_Path is null Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 Else  '*|' + convert(nVarChar(10),@Char_Id) + '|'
                        	  	  	        END,
 	  	  	  	    UC_Path =   CASE 
                        WHEN @Is_Defined IS NULL And UC_Path IS NOT NULL Then UC_Path  +  convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 32768 <> 32768 And UC_Path IS NOT NULL Then UC_Path + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @Is_Defined & 32768 = 32768 And UC_Path IS NULL Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When  @Is_Defined & 32768 =  32768  and Substring(UC_Path,1,1) = '*' Then '|' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 When @DerivedFromP is Not Null Then   '||' + convert(nVarChar(10),@Char_Id) + '|'
 	  	  	  	  	  	 WHEN @DerivedFromP is null and UC_Path is null Then  '|' + convert(nVarChar(10),@Char_Id) + '|'
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
   Drop Table #CharIds
Update #Path set TF_Path =   CASE 
 	  	  	  	 When  Substring( TF_Path ,1,1) = '*' Then Substring( TF_Path ,2,datalength( TF_Path ))
 	  	  	  	 Else TF_Path
             	  	  	         END,
 	  	 SIG_Path =   CASE 
 	  	  	  	 When  Substring( SIG_Path ,1,1) = '*' Then Substring( SIG_Path ,2,datalength( SIG_Path ))
 	  	  	  	 Else SIG_Path
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
         c.Char_Id,
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
 	  	  SIG_Path
    FROM  Characteristics c, Specifications s
    LEFT JOIN Active_Specs a ON (s.Spec_Id = a.Spec_Id) and (a.Char_Id = @Char_Id)  AND (Effective_Date <= @Now) AND
          ((Expiration_Date IS NULL) OR ((Expiration_Date IS NOT NULL) AND (Expiration_Date > @Now)))
    LEFT Join #Path p On p.Spec_Id = s.Spec_Id and p.Char_Id = @Char_Id
     WHERE c.Char_Id = @Char_Id  and (s.Prop_Id = @Prop_Id)  
     Order by c.Char_Id
  SELECT  
         t.Spec_Id,
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
         Expiration_Date = null,
         t.Is_Defined,
         t.not_defined,
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
 	  	  SIG_Path
    FROM #TransPP t  
    INNER JOIN Characteristics c ON (c.Prop_Id = @Prop_Id) AND (c.Char_Id = t.Char_Id)
    INNER JOIN Specifications s ON (s.Prop_Id = @Prop_Id) AND (s.Spec_Id = t.Spec_Id) AND (t.Char_Id = @Char_Id)
    LEFT Join #Path p On p.Spec_Id = s.Spec_Id and p.Char_Id = @Char_Id
   drop table #Path
