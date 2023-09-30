CREATE PROCEDURE dbo.spRS_SearchVariables
@ProdLine int = Null,
@ProdUnit int = Null,
@ProdGroup int = Null,
@VarSearchDesc varchar(50) = Null,
@ExcludeStr varchar(8000) = Null,
@TimeBased int = NULL
 AS
/*
TimeBased = NULL 	 means get all variables
TimeBased = 0 	  	 means only get Time based variables
TimeBased = 1 	  	 means only get Event based variables
*/
Declare @INstr VarChar(7999)
Declare @I int
Declare @Id int
Create Table #T (OrderID Int,Var_Id Int)
Select @I = 1
Select @INstr = @ExcludeStr + ','
While (Datalength(LTRIM(RTRIM(@INstr))) > 1) 
  Begin
 	 Select @Id = SubString(@INstr,1,CharIndex(',',@INstr)-1)
    insert into #T (OrderId,Var_Id) Values (@I,@Id)
    Select @I = @I + 1
 	 Select @INstr = SubString(@INstr,CharIndex(',',@INstr),Datalength(@INstr))
 	 Select @INstr = Right(@INstr,Datalength(@INstr)-1)
  End
Create Table #ET(ET_Id INT)
-- Get All Variables
If @TimeBased Is Null
 	 Insert Into #ET(ET_Id) Select ET_Id from Event_Types
-- Get Time Based Variables
If @TimeBased = 0
 	 Begin
 	  	 Insert Into #ET(ET_Id) Values(0)  -- Time
 	  	 Insert Into #ET(ET_Id) Values(5)  -- Product/Time
 	 End
-- Get Event Based Variables
If @TimeBased = 1
 	 Begin
 	  	 Insert Into #ET(ET_Id) Values(1)  -- Production Event
 	  	 Insert Into #ET(ET_Id) Values(14) -- User Defined Events
 	 End
If @ProdLine Is Null
  Begin
    If @VarSearchDesc Is Null
      Select VarId = Var_Id, VarDesc = V.Var_Desc, ProdLine = PL.PL_Id, ProdUnit = PU.PU_Id, ProdGroup = PUG.PUG_Id
      from variables V
      Join PU_Groups PUG on PUG.PUG_Id = v.PUG_Id
      Join Prod_Units PU on PU.PU_Id = v.PU_Id and v.var_Id > 0 and v.PU_Id > 0
      Join Prod_Lines PL on PL.PL_Id = PU.PL_ID
      Join #ET on #ET.ET_Id = Event_Type
      Where Var_Id Not In (Select Var_Id From #t)
      Order by ProdLine, ProdUnit, ProdGroup, VarDesc
    Else
      Select VarId = Var_Id, VarDesc = V.Var_Desc, ProdLine = PL.PL_Id, ProdUnit = PU.PU_Id, ProdGroup = PUG.PUG_Id
      from variables V
      Join PU_Groups PUG on PUG.PUG_Id = v.PUG_Id
      Join Prod_Units PU on PU.PU_Id = v.PU_Id and PU.PU_Id > 0
      Join Prod_Lines PL on PL.PL_Id = PU.PL_ID
   	   Join #ET on #ET.ET_Id = Event_Type
      Where v.Var_Desc Like '%' + Ltrim(rtrim(@VarSearchDesc)) + '%'
      and Var_Id Not In (Select Var_Id From #t) 
      Order by ProdLine, ProdUnit, ProdGroup, VarDesc
  End
Else If @ProdUnit Is Null
  Begin
    If @VarSearchDesc Is Null
      Select VarId = Var_Id, VarDesc = V.Var_Desc, ProdLine = PL.PL_Id, ProdUnit = PU.PU_Id, ProdGroup = PUG.PUG_Id
      from variables V
      Join PU_Groups PUG on PUG.PUG_Id = v.PUG_Id
      Join Prod_Units PU on PU.PU_Id = v.PU_Id and PU.PU_Id > 0
      Join Prod_Lines PL on PL.PL_Id = PU.PL_Id and PL.PL_Id = @ProdLine and PL.PL_Id > 0
 	   Join #ET on #ET.ET_Id = Event_Type
 	  Where Var_Id Not In (Select Var_Id From #t)
      Order by ProdLine, ProdUnit, ProdGroup, VarDesc
    Else
      Select VarId = Var_Id, VarDesc = V.Var_Desc, ProdLine = PL.PL_Id, ProdUnit = PU.PU_Id, ProdGroup = PUG.PUG_Id
      from variables V
      Join PU_Groups PUG on PUG.PUG_Id = v.PUG_Id
      Join Prod_Units PU on PU.PU_Id = v.PU_Id and PU.PU_Id > 0
      Join Prod_Lines PL on PL.PL_Id = PU.PL_Id and PL.PL_Id = @ProdLine and PL.PL_Id > 0
 	   Join #ET on #ET.ET_Id = Event_Type
      Where v.Var_Desc Like '%' + Ltrim(rtrim(@VarSearchDesc)) + '%' 
      and Var_Id Not In (Select Var_Id From #t)
      Order by ProdLine, ProdUnit, ProdGroup, VarDesc
  End
Else If @ProdGroup Is Null
  Begin
    If @VarSearchDesc Is Null
      Select VarId = Var_Id, VarDesc = V.Var_Desc, ProdLine = PL.PL_Id, ProdUnit = PU.PU_Id, ProdGroup = PUG.PUG_Id
      from variables V
      Join PU_Groups PUG on PUG.PUG_Id = v.PUG_Id
      Join Prod_Units PU on PU.PU_Id = v.PU_Id and PU.PU_Id = @ProdUnit and @ProdUnit > 0 --v.PU_Id and PU.PU_Id > 0
      Join Prod_Lines PL on PL.PL_Id = PU.PL_Id and PL.PL_Id = @ProdLine and PL.PL_Id > 0
 	   Join #ET on #ET.ET_Id = Event_Type
 	  Where Var_Id Not In (Select Var_Id From #t)
      Order by ProdLine, ProdUnit, ProdGroup, VarDesc
    Else
      Select VarId = Var_Id, VarDesc = V.Var_Desc, ProdLine = PL.PL_Id, ProdUnit = PU.PU_Id, ProdGroup = PUG.PUG_Id
      from variables V
      Join PU_Groups PUG on PUG.PUG_Id = v.PUG_Id
      Join Prod_Units PU on PU.PU_Id = v.PU_Id and PU.PU_Id = @ProdUnit and @ProdUnit > 0 --v.PU_Id and PU.PU_Id > 0
      Join Prod_Lines PL on PL.PL_Id = PU.PL_Id and PL.PL_Id = @ProdLine and PL.PL_Id > 0
 	   Join #ET on #ET.ET_Id = Event_Type
      Where v.Var_Desc Like '%' + Ltrim(rtrim(@VarSearchDesc)) + '%' 
      and Var_Id Not In (Select Var_Id From #t)
      Order by ProdLine, ProdUnit, ProdGroup, VarDesc
  End
Else
  Begin
    If @VarSearchDesc Is Null
      Select VarId = Var_Id, VarDesc = V.Var_Desc, ProdLine = PL.PL_Id, ProdUnit = PU.PU_Id, ProdGroup = PUG.PUG_Id
      from variables V
      Join PU_Groups PUG on PUG.PUG_Id = @ProdGroup and PUG.PUG_Id = v.PUG_Id
      Join Prod_Units PU on PU.PU_Id = @ProdUnit and @ProdUnit > 0 --v.PU_Id and PU.PU_Id > 0
      Join Prod_Lines PL on PL.PL_Id = PU.PL_Id and PL.PL_Id = @ProdLine and PL.PL_Id > 0
 	   Join #ET on #ET.ET_Id = Event_Type
      Where Var_Id Not In (Select Var_Id From #t)
      Order by ProdLine, ProdUnit, ProdGroup, VarDesc
    Else
      Select VarId = Var_Id, VarDesc = V.Var_Desc, ProdLine = PL.PL_Id, ProdUnit = PU.PU_Id, ProdGroup = PUG.PUG_Id
      from variables V
      Join PU_Groups PUG on PUG.PUG_Id = @ProdGroup and PUG.PUG_Id = v.PUG_Id
      Join Prod_Units PU on PU.PU_Id = @ProdUnit and @ProdUnit > 0 --v.PU_Id and PU.PU_Id > 0
      Join Prod_Lines PL on PL.PL_Id = PU.PL_Id and PL.PL_Id = @ProdLine and PL.PL_Id > 0
 	   Join #ET on #ET.ET_Id = Event_Type
      Where v.Var_Desc Like '%' + Ltrim(rtrim(@VarSearchDesc)) + '%' 
      and Var_Id Not In (Select Var_Id From #t)
      Order by ProdLine, ProdUnit, ProdGroup, VarDesc
  End
Drop Table #t
Drop Table #ET
