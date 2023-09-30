-- spSS_SearchVariable null,null,null,null,null,null,null,null,null,null,null,null,0
Create Procedure dbo.spSS_SearchVariable
 @PLId int = NULL,
 @PUId int = NULL,
 @PUGId int = NULL,
 @Description nVarChar(50) = NULL,
 @DSId int = NULL,
 @STId int = NULL,
 @ProdUnits nVarChar(255) = NULL,
 @ETIds 	  	 nVarChar(255) = Null,
 @VarAlias 	 Int = 0,
 @PEIId int = NULL,
 @EventSubtypeId int = NULL, 
 @HasAlarmTemplate int = 0,
 @StringSpecificationSetting Int = 0
AS
Select @VarAlias = Coalesce(@VarAlias,0)
 Declare @SQLCommand Varchar(2500),
 	  @SQLCond0 nVarChar(255),
              @SQLCond1 nVarChar(255),
              @SQLCond2 nVarChar(255),
              @SQLCond3 nVarChar(255),
              @SQLCond4 nVarChar(255),
              @SQLCond5 nVarChar(255),
              @SQLCond6 nVarChar(255),
              @SQLCond7 nVarChar(255)
------------------------------------------------------------------------
-- Initialize variables
------------------------------------------------------------------------
 Select @SQLCond0 = Null
 Select @SQLCond1 = Null
 Select @SQLCond2 = Null
 Select @SQLCond3 = Null
 Select @SQLCond4 = Null
 Select @SQLCond5 = Null
 Select @SQLCond6 = Null
 Select @SQLCond7 = Null
 If (@VarAlias = 1)
  BEGIN
 	  Select @SQLCommand = 'Select Distinct [Var_Desc] = V.Var_Desc + ''['' +   v.Test_Name + '']'',' 
  END
 Else
  BEGIN
 	  Select @SQLCommand = 'Select Distinct [Var_Desc] = V.Var_Desc,'
  END
 Select @SQLCommand = @SQLCommand + 'V.Var_Id, V.DS_Id, DS.Ds_Desc, V.Event_Type, ET.ET_Desc, V.Data_Type_Id,  DT.Data_Type_Desc, ' +
                      'PU.PL_Id,  PL.PL_Desc, ST.ST_Desc, V.PU_Id, V.PUG_Id,  ' +
                      'PU.PU_Desc, PG.PUG_Desc,V.Test_Name,SP.SPC_Calculation_Type_Desc From Variables V Inner Join Data_Source DS On ' + 
                      'V.DS_Id = DS.DS_id Inner Join Event_Types ET on V.Event_Type = ET.ET_Id ' +
                      'Inner Join Data_Type DT on V.Data_Type_Id = DT.Data_Type_Id ' +
                      'Left Outer Join Sampling_Type ST on V.Sampling_Type = ST.ST_Id ' +
 	  	        	  	   'Inner Join Prod_Units PU on V.PU_Id = PU.PU_Id ' +
 	  	        	  	   'Inner Join PU_Groups PG on V.PUG_Id = PG.PUG_Id ' +
                      'Inner Join Prod_Lines PL on PU.PL_Id = PL.PL_Id ' +
                      'Left Outer Join SPC_Calculation_Types SP on V.SPC_Calculation_Type_Id = SP.SPC_Calculation_Type_Id '
 If (@HasAlarmTemplate <> 0)
  BEGIN
    Select @SQLCommand = @SQLCommand + 'Inner Join Alarm_Template_Var_Data ATD on ATD.Var_Id = V.Var_Id '
  END
 Select @SQLCommand = @SQLCommand + 'Where PU.PU_Id <>0 '
----------------------------------------------------------------------
-- Append PLid to the SQL command if this parameter was passed
-----------------------------------------------------------------------
 If (@PLId Is Not Null) And (@PLID <>0)
  BEGIN
   Select @SQLCond0 = ' PU.PL_Id = ' + Convert(nVarChar(5), @PLId)
   Select @SQLCommand = @SQLCommand + ' And ' + @SQLCond0
  END
---------------------------------------------------------------------
-- Append PUid to the SQL command if this parameter was passed
--------------------------------------------------------------------- 
 If (@PUId Is Not Null) And (@PUID <>0)
  BEGIN
   Select @SQLCond1 = ' V.PU_Id = ' + Convert(nVarChar(5), @PUId)
   Select @SQLCommand = @SQLCommand + ' And ' + @SQLCond1
  END
---------------------------------------------------------------------
-- Append PUGid to the SQL command if this parameter was passed
--------------------------------------------------------------------- 
 If (@PUGID Is Not Null) And (@PUGID <>0)
  BEGIN
   Select @SQLCond2 =  ' V.PUG_Id = ' + Convert(nVarChar(5), @PUGId)
   Select @SQLCommand = @SQLCommand + ' And ' + @SQLCond2
  END
---------------------------------------------------------------------
-- Append Description to the SQL command if this parameter was passed
--------------------------------------------------------------------- 
 If (@Description Is Not Null) And (Len(@Description)>0)
  BEGIN
   Select @SQLCond3 = " V.Var_Desc Like '%" + @Description + "%'"
   Select @SQLCommand = @SQLCommand + ' And ' + @SQLCond3
  END
---------------------------------------------------------------------
-- Append DSid to the SQL command if this parameter was passed
--------------------------------------------------------------------- 
 If (@DsId Is Not Null) And (@DSID <>0)
  BEGIN
   Select @SQLCond4 = ' V.DS_Id = ' +Convert(nVarChar(5), @DSId)
   Select @SQLCommand = @SQLCommand + ' And ' + @SQLCond4
  END
 If (@ETIds Is Not Null) And (Len(@ETIds) > 0)
  BEGIN
   Select @SQLCond4 = ' V.Event_Type in (' +Convert(nVarChar(255), @ETIds) + ')'
   Select @SQLCommand = @SQLCommand + ' And ' + @SQLCond4
  END
---------------------------------------------------------------------
-- Append STid to the SQL command if this parameter was passed
--------------------------------------------------------------------- 
 If (@STId Is Not Null) And (@STID <>0)
  BEGIN
   Select @SQLCond5 = ' V.Sampling_Type = ' +Convert(nVarChar(5), @STId)
   Select @SQLCommand = @SQLCommand + ' And ' + @SQLCond5
  END
---------------------------------------------------------------------
-- Append multiple PUId's to the SQL command if this parameter was passed
--------------------------------------------------------------------- 
 If (@VarAlias = 1)
  BEGIN
   Select @SQLCommand = @SQLCommand + ' And Test_Name Is not Null'
  END
---------------------------------------------------------------------
-- Null Variable Alias only
--------------------------------------------------------------------- 
 If (@ProdUnits Is Not Null) And (Len(@ProdUnits)>0)
  BEGIN
   Select @SQLCond6 = ' PU.PU_Id in (' +Convert(nVarChar(255), @ProdUnits) + ')'
   Select @SQLCommand = @SQLCommand + ' And ' + @SQLCond6
  END
---------------------------------------------------------------------
-- Append PEIId to the SQL command if this parameter was passed
--------------------------------------------------------------------- 
 If (@PEIId Is Not Null) And (@PEIId <>0)
  BEGIN
   Select @SQLCond7 = ' V.PEI_Id = ' +Convert(nVarChar(5), @PEIId)
   Select @SQLCommand = @SQLCommand + ' And ' + @SQLCond7
  END
 If (@EventSubtypeId Is Not Null) And (@EventSubtypeId <>0)
  BEGIN
   Select @SQLCond7 = ' V.Event_SubType_Id = ' +Convert(nVarChar(5), @EventSubtypeId)
   Select @SQLCommand = @SQLCommand + ' And ' + @SQLCond7
  END
---------------------------------------------------------------------
-- Append StringSpecification setting to the SQL command if this parameter was passed
--------------------------------------------------------------------- 
If (@StringSpecificationSetting Is Not Null) And (@StringSpecificationSetting <>0)
BEGIN
 	 IF @StringSpecificationSetting  = 1
 	 BEGIN
 	  	 Select @SQLCond7 = ' ((V.String_Specification_Setting Is Null Or V.String_Specification_Setting  = 0) and (v.Data_Type_Id > 50 or v.Data_Type_Id In (3,8)))' 
 	  	 Select @SQLCommand = @SQLCommand + ' And ' + @SQLCond7
 	 END
 	 IF @StringSpecificationSetting = 2
 	 BEGIN
 	  	 Select @SQLCond7 = ' V.String_Specification_Setting = 1' 
 	  	 Select @SQLCommand = @SQLCommand + ' And ' + @SQLCond7
 	 END
 	 IF @StringSpecificationSetting = 3
 	 BEGIN
 	  	 Select @SQLCond7 = ' V.String_Specification_Setting = 2 and (v.Data_Type_Id > 50)'  
 	  	 Select @SQLCommand = @SQLCommand + ' And ' + @SQLCond7
 	 END
END
---------------------------------------------------------------------
-- Append Order by clause to the SQL command and run it
--------------------------------------------------------------------- 
  Select @SQLCommand = @SQLCommand + ' Order by [Var_Desc] '
  Exec (@SQLCommand)
