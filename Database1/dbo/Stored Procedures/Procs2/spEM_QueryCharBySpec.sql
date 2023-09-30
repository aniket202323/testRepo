CREATE PROCEDURE dbo.spEM_QueryCharBySpec
  @IsProperty 	 Int,
  @VarId 	 nvarchar(1000),
  @Limit 	 nvarchar(1000),
  @Oper 	  	 nvarchar(1000),
  @Values 	 VarChar(7000),
  @Actions 	 nvarchar(1000)
 AS
/* Operators 
  0  =  "<"
  1 =   "<="
  2 =   "="
  3 =   ">="
  4 =   ">"
  5 =   "<>"
  6 =   "Not Defined"
  7 =   "Defined"
  8 =   "Like"
  9 =   "Not Like"
****Limits******
0 = "L Entry"
1 = "L Reject"
2 = "L Warning"
3 = "L User"
4 = "Target"
5 = "U User"
6 = "U Warning"
7 = "U Reject"
8 = "U Entry"
9 = "Test Frequency"
10 = "Signature"
11 = "L Control"
12 = "T Control"
13 = "U Control"
14 = "Characteristic"
*****Actions******
0 = "Add"
1 = "Keep"
*/
Declare @V 	 nVarChar(10),
 	 @iL 	 int,
 	 @L 	 nvarchar(20),
 	 @iO 	 int,
 	 @O 	 nvarchar(20),
 	 @Val 	 nVarChar(27),
 	 @A 	 Int,
 	 @SQL   	 nvarchar(1000),
 	 @DT 	 Int,
 	 @PropId Int,
 	 @PU_Id Int,
 	 @Now 	 Datetime
 Select @Now = dbo.fnServer_CmnGetDate(getUTCdate())
Create Table #Characteristics (Id Int)
While (len( LTRIM(RTRIM(@VarId))) > 1) 
  Begin
       Select @V = SubString(@VarId,1,CharIndex(Char(1),@VarId)-1)
       If (@Limit = '') or (@Oper = '') or (@Values = '') 
 	      Begin
 	  	   If @IsProperty = 1
 	  	  	 Begin
 	       	   Select  [Id] = Char_Id From Characteristics Where Prop_Id =  convert(int,@V)
 	       	   Return
 	  	  	 End
 	  	   Else
 	  	     Begin
 	       	   Select  [Id] = Prod_Id From PU_Products  Where PU_Id =  convert(int,@V)
 	       	   Return
 	  	     End
 	      End
 	    IF @IsProperty = 1
         Select @Dt = Data_Type_Id,@PropId = Prop_Id from specifications where spec_Id = convert(int,@V)
 	    Else
 	  	  Begin
        	    Select @Dt = Data_Type_Id,@PU_Id = PU_Id from Variables where Var_Id = convert(int,@V)
 	  	    Select @PU_Id = coalesce(Master_Unit,PU_Id) from Prod_Units Where Pu_Id = @PU_Id
 	  	  End
       Select @VarId = SubString(@VarId,CharIndex(Char(1),@VarId),len(@VarId))
       Select @VarId = Right(@VarId,len(@VarId)-1)
       Select @iL = Convert(Int,SubString(@Limit,1,CharIndex(Char(1),@Limit)-1))
       Select @L = Case    When @iL = 0 Then ' L_Entry '
 	  	  	 When @iL = 1 Then ' L_Reject '
 	  	  	 When @iL = 2 Then ' L_Warning '
 	  	  	 When @iL = 3 Then ' L_User '
 	  	  	 When @iL = 4 Then ' Target '
 	  	  	 When @iL = 5 Then ' U_User '
 	  	  	 When @iL = 6 Then ' U_Warning '
 	  	  	 When @iL = 7 Then ' U_Reject '
 	  	  	 When @iL = 8 Then ' U_Entry '
 	  	  	 When @iL = 9 Then ' Test_Freq '
 	  	  	 When @iL = 10 Then ' ESignature_Level '
 	  	  	 When @iL = 11 Then ' L_Control '
 	  	  	 When @iL = 12 Then ' T_Control '
 	  	  	 When @iL = 13 Then ' U_Control '
                             End
       Select @Limit = SubString(@Limit,CharIndex(Char(1),@Limit),len(@Limit))
       Select @Limit = Right(@Limit,len(@Limit)-1)
       Select @iO = Convert(Int,SubString(@Oper,1,CharIndex(Char(1),@Oper)-1))
       Select @O = Case    When @iO =  0 Then ' < '
 	  	  	 When  @iO = 1 Then ' <= '
 	  	  	 When @iO =  2 Then ' = '
 	  	  	 When  @iO = 3 Then ' >= '
 	  	  	 When @iO =  4 Then ' > '
 	  	  	 When @iO =  5 Then ' <> '
 	  	  	 When @iO =  6 Then ' Is Null '
 	  	  	 When @iO =  7 Then ' Is Not Null '
 	  	  	 When @iO =  8 Then ' Like '
 	  	  	 When @iO =  9 Then ' Not Like '
 	  	 End
       Select @Oper = SubString(@Oper,CharIndex(Char(1),@Oper),len(@Oper))
       Select @Oper = Right(@Oper,len(@Oper)-1)
       Select @Val = SubString(@Values,1,CharIndex(Char(1),@Values)-1)
       Select @Values = SubString(@Values,CharIndex(Char(1),@Values),len(@Values))
       Select @Values = Right(@Values,len(@Values)-1)
       Select @Val = Case When @iO =  6 Then  ''
 	  	  	 When @iO =  7 Then  ''
 	  	  	 When @iO =  8 Then  REPLACE(@Val,'*','%')
 	  	  	 When @iO =  9 Then  REPLACE(@Val,'*','%')
 	  	  	 Else @Val
 	             End
       Select @Val = Case When @iO =  8 Then '''' + REPLACE(@Val,'?','_') + ''''
 	  	  	 When @iO =  9 Then  '''' + REPLACE(@Val,'?','_') + ''''
 	  	  	 Else @Val
 	             End
       Select @A = Convert(Int,SubString(@Actions,1,CharIndex(Char(1),@Actions)-1))
       Select @Actions = SubString(@Actions,CharIndex(Char(1),@Actions),len(@Actions))
       Select @Actions = Right(@Actions,len(@Actions)-1)
If @IsProperty = 1
 Begin
 	   If @iL = 11 and (@iO = 6 or @iO = 7) -- empty resultset
 	     Begin
 	       Select @Sql = 'Select Char_Id From Characteristics Where Prop_Id is null' 
 	     End
 	   Else If @iL = 11 and (@iO = 8 or @iO = 9)
 	     Begin
 	       Select @Sql = 'Select Char_Id From Characteristics Where Prop_Id = ' + Convert(nVarChar(10),@PropId) 
 	       Select @Sql =  @Sql + ' and Char_Desc ' + @O  + '' + @Val + ''
 	     End
 	   Else If @iL = 11 and (@iO <> 8 and @iO <> 9)
 	     Begin
 	       Select @Sql = 'Select Char_Id From Characteristics Where Prop_Id = ' + Convert(nVarChar(10),@PropId) 
 	       Select @Sql =  @Sql + ' and Char_Desc ' + @O  + ' ''' + @Val + ''''
 	     End
 	   Else If (@DT > 50 or @Dt = 3 ) and (@iO = 8 or @iO = 9)
 	     Begin
 	       Select @Sql = 'Select Char_Id From Active_Specs Where Spec_Id = ' + @V + ' and ' + @L  + ' ' 
 	       Select @Sql = @Sql + @O  + @Val + ' and  Effective_Date < '''  + Convert(nvarchar(20),@Now) 
 	       Select @Sql = @Sql + ''' and ( Expiration_Date > ''' + Convert(nvarchar(20),@Now) + ''' Or Expiration_Date Is Null)'
 	     End
 	   Else If (@DT > 50 or @Dt = 3 ) and (@iO <> 6 and  @iO <> 7)
 	     Begin
 	       Select @Sql = 'Select Char_Id From Active_Specs Where Spec_Id = ' + @V + ' and ' + @L  + ' ' 
 	       Select @Sql = @Sql + @O + ' ''' + @Val + ''' and  Effective_Date < '''  + Convert(nvarchar(20),@Now) 
 	       Select @Sql = @Sql + ''' and ( Expiration_Date > ''' + Convert(nvarchar(20),@Now) + ''' Or Expiration_Date Is Null)'
 	     End
 	   Else 
 	     Begin
 	       Select @Sql = 'Select Char_Id From Active_Specs Where Spec_Id = ' + @V + ' and Convert(Real,' + @L  + ') ' 
 	       Select @Sql = @Sql + @O  + @Val + ' and  Effective_Date < '''  + Convert(nvarchar(20),@Now) 
 	       Select @Sql = @Sql + ''' and ( Expiration_Date > ''' + Convert(nvarchar(20),@Now) + ''' Or Expiration_Date Is Null)'
 	     End
 	 
 	   If @A = 0
 	      Begin
 	  	 Select @SQL = 'Insert into #Characteristics ' + @Sql
 	  	 Execute (@SQL)
 	  	 If @iO = 6 and @iL <> 11
 	    	   Begin
 	  	     Select @Sql = 'Select Char_Id From Characteristics c Where Prop_Id = ' + Convert(nVarChar(10),@PropId)
 	  	     Select @Sql = @Sql + ' and (Select Count(*) from Active_Specs Where Spec_Id = ' + @V +  ' and  char_Id = c.char_Id ' 
 	  	     Select @Sql = @Sql + ' and  Effective_Date < '''  + Convert(nvarchar(20),@Now) 
 	  	     Select @Sql = @Sql + ''' and ( Expiration_Date > ''' + Convert(nvarchar(20),@Now) + ''' Or Expiration_Date Is Null)) = 0'
 	  	     Select @SQL = 'Insert into #Characteristics ' + @Sql
 	  	     Execute (@SQL)
 	  	   End
 	      End
 	   Else
 	     Begin
 	  	 Select @SQL = 'Delete From #Characteristics Where Id Not In  ( ' + @Sql + ' )'
 	  	 Execute (@SQL)
 	  	 If @iO = 6 and @iL <> 11
 	    	   Begin
 	  	     Select @Sql = 'Select Char_Id From Characteristics c Where Prop_Id = ' + Convert(nVarChar(10),@PropId)
 	  	     Select @Sql = @Sql + ' and (Select Count(*) from Active_Specs Where Spec_Id = ' + @V +  ' and  char_Id = c.char_Id ' 
 	  	     Select @Sql = @Sql + ' and  Effective_Date < '''  + Convert(nvarchar(20),@Now) 
 	  	     Select @Sql = @Sql + ''' and ( Expiration_Date > ''' + Convert(nvarchar(20),@Now) + ''' Or Expiration_Date Is Null)) = 0'
 	  	     Select @SQL = 'Delete From #Characteristics Where Id Not In ( ' + @Sql + ' )'
 	  	     Execute (@SQL)
 	  	   End
 	     End
  End
Else
  Begin
 	   If @iL = 11 and (@iO = 6 or @iO = 7) -- empty resultset
 	     Begin
 	       Select @Sql = 'Select Prod_Id From PU_Products Where Prod_Id is null' 
 	     End
 	   Else If @iL = 11 and (@iO = 8 or @iO = 9)
 	     Begin
 	       Select @Sql = 'Select p.Prod_Id From PU_Products pu Join Products p on p.prod_Id = pu.prod_Id'
 	  	   Select @Sql = @Sql + ' Where PU_Id = ' + Convert(nVarChar(10),@PU_Id) 
 	       Select @Sql =  @Sql + ' and Prod_Code ' + @O  + '' + @Val + ''
 	     End
 	   Else If @iL = 11 and (@iO <> 8 and @iO <> 9)
 	     Begin
 	       Select @Sql = 'Select p.Prod_Id From PU_Products pu Join Products p on p.prod_Id = pu.prod_Id'
 	  	   Select @Sql = @Sql + ' Where PU_Id = ' + Convert(nVarChar(10),@PU_Id) 
 	       Select @Sql =  @Sql + ' and Prod_Code ' + @O  + ' ''' + @Val + ''''
 	     End
 	   Else If (@DT > 50 or @Dt = 3 ) and (@iO = 8 or @iO = 9)
 	     Begin
 	       Select @Sql = 'Select Prod_Id From Var_Specs Where Var_Id = ' + @V + ' and ' + @L  + ' ' 
 	       Select @Sql = @Sql + @O  + @Val + ' and  Effective_Date < '''  + Convert(nvarchar(20),@Now) 
 	       Select @Sql = @Sql + ''' and ( Expiration_Date > ''' + Convert(nvarchar(20),@Now) + ''' Or Expiration_Date Is Null)'
 	     End
 	   Else If (@DT > 50 or @Dt = 3 ) and (@iO <> 6 and  @iO <> 7)
 	     Begin
 	       Select @Sql = 'Select Prod_Id From Var_Specs Where Var_Id = ' + @V + ' and ' + @L  + ' ' 
 	       Select @Sql = @Sql + @O + ' ''' + @Val + ''' and  Effective_Date < '''  + Convert(nvarchar(20),@Now) 
 	       Select @Sql = @Sql + ''' and ( Expiration_Date > ''' + Convert(nvarchar(20),@Now) + ''' Or Expiration_Date Is Null)'
 	     End
 	   Else 
 	     Begin
 	       Select @Sql = 'Select Prod_Id From Var_Specs Where Var_Id = ' + @V + ' and Convert(Real,' + @L  + ') ' 
 	       Select @Sql = @Sql + @O  + @Val + ' and  Effective_Date < '''  + Convert(nvarchar(20),@Now) 
 	       Select @Sql = @Sql + ''' and ( Expiration_Date > ''' + Convert(nvarchar(20),@Now) + ''' Or Expiration_Date Is Null)'
 	     End
 	 
 	   If @A = 0
 	      Begin
 	  	 Select @SQL = 'Insert into #Characteristics ' + @Sql
 	  	 Execute (@SQL)
 	  	 If @iO = 6 and @iL <> 11
 	    	   Begin
 	  	     Select @Sql = 'Select Prod_Id From PU_Products c Where PU_Id = ' + Convert(nVarChar(10),@PU_Id)
 	  	     Select @Sql = @Sql + ' and (Select Count(*) from Var_Specs Where Var_Id = ' + @V +  ' and  Prod_Id = c.Prod_Id ' 
 	  	     Select @Sql = @Sql + ' and  Effective_Date < '''  + Convert(nvarchar(20),@Now) 
 	  	     Select @Sql = @Sql + ''' and ( Expiration_Date > ''' + Convert(nvarchar(20),@Now) + ''' Or Expiration_Date Is Null)) = 0'
 	  	     Select @SQL = 'Insert into #Characteristics ' + @Sql
 	  	     Execute (@SQL)
 	  	   End
 	      End
 	   Else
 	     Begin
 	  	 Select @SQL = 'Delete From #Characteristics Where Id Not In  ( ' + @Sql + ' )'
 	  	 Execute (@SQL)
 	  	 If @iO = 6 and @iL <> 11
 	    	   Begin
 	  	     Select @Sql = 'Select Prod_Id From PU_Products c Where PU_Id = ' + Convert(nVarChar(10),@PU_Id)
 	  	     Select @Sql = @Sql + ' and (Select Count(*) from Var_Specs Where Var_Id = ' + @V +  ' and Prod_Id = c.Prod_Id ' 
 	  	     Select @Sql = @Sql + ' and  Effective_Date < '''  + Convert(nvarchar(20),@Now) 
 	  	     Select @Sql = @Sql + ''' and ( Expiration_Date > ''' + Convert(nvarchar(20),@Now) + ''' Or Expiration_Date Is Null)) = 0'
 	  	     Select @SQL = 'Delete From #Characteristics Where Id Not In ( ' + @Sql + ' )'
 	  	     Execute (@SQL)
 	  	   End
 	     End
 	   End
  End
Select Distinct Id from #Characteristics
Drop Table #Characteristics
