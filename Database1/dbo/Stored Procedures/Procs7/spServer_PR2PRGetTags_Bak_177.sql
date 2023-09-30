CREATE PROCEDURE dbo.[spServer_PR2PRGetTags_Bak_177]
@VarIdMask nVarChar(1000)
 AS 
Set NoCount on
If (IsNumeric(@VarIdMask) = 1)
  Begin
    Select 
      Var_Id,
      Var_Desc,
      Eng_Units,
      DataType = Case 
        When Data_Type_Id = 1  Then 'Integer' 
        When Data_Type_Id = 2  Then 'Float'
        When Data_Type_Id = 3  Then 'String'
        When Data_Type_Id = 4  Then 'Integer'
        When Data_Type_Id = 6  Then 'Integer'
        When Data_Type_Id = 7  Then 'Float'
        When Data_Type_Id = 8  Then 'String'
        When Data_Type_Id > 50 Then 'String'
        Else 'Other' 
      End 
    From Variables_Base 
    Where Var_Id = Convert(int,@VarIdMask)
 	  	 ORDER BY Var_Desc
  End
Else
  Begin
 	  	 DECLARE @variableName nVarChar(1000)
 	  	 DECLARE @unitName nVarChar(1000)          
 	  	 DECLARE @lineName nVarChar(1000)
 	  	 DECLARE @temporaryPointerName int
 	  	 DECLARE @temporaryPointerLine int
 	  	 DECLARE @DoFullQuery bit
 	  	 SELECT @DoFullQuery = 0
 	  	 -- VariableName
 	  	 SELECT @temporaryPointerName = PATINDEX('%.%', REVERSE (@VarIdMask))
 	  	 IF @temporaryPointerName <> 0 -- Check if a divide sign is found, if not just use every variable
 	  	  	 BEGIN
 	  	  	  	 SELECT @variableName = (RIGHT (@VarIdMask, (@temporaryPointerName - 1)))            
 	  	  	  	 -- LineName
 	  	  	  	 SELECT @temporaryPointerLine = PATINDEX('%.%', @VarIdMask)
 	  	  	  	 IF @temporaryPointerLine <> 0 -- Check if a divide sign is found, if not just use every line
 	  	  	  	  	 BEGIN
 	  	  	  	  	  	 SELECT @lineName = (LEFT (@VarIdMask, (@temporaryPointerLine - 1)))            
 	  	  	  	  	  	 -- UnitName
 	  	  	  	  	  	 SELECT @unitName = (SUBSTRING (@VarIdMask, (@temporaryPointerLine+1), LEN (@VarIdMask)-@temporaryPointerLine-@temporaryPointerName))
 	  	  	  	  	  	 SELECT @DoFullQuery = 1
 	  	  	  	  	 END
 	  	  	 END
 	  	 If (@DoFullQuery = 1)
 	  	  	 Begin
 	  	  	  	 Select 
 	  	  	  	  	 Full_Tag = REPLACE(REPLACE(REPLACE(l.PL_Desc,'.',''),' ',''),';','') + '.' + 
 	  	  	  	  	  	  	  	  	  	  	  	  REPLACE(REPLACE(REPLACE(u.PU_Desc,'.',''),' ',''),';','') + '.' + 
 	  	  	  	  	  	  	  	  	  	  	  	  REPLACE(REPLACE(REPLACE(v.Var_Desc,'.',''),' ',''),';',''),
 	  	  	  	  	 v.Var_Desc,
 	  	  	  	  	 v.Eng_Units,
 	  	  	  	  	 DataType = Case 
 	  	  	  	  	  	 When v.Data_Type_Id = 1  Then 'Integer' 
 	  	  	  	  	  	 When v.Data_Type_Id = 2  Then 'Float'
 	  	  	  	  	  	 When v.Data_Type_Id = 3  Then 'String'
 	  	  	  	  	  	 When v.Data_Type_Id = 4  Then 'Integer'
 	  	  	  	  	  	 When v.Data_Type_Id = 6  Then 'Integer'
 	  	  	  	  	  	 When v.Data_Type_Id = 7  Then 'Float'
 	  	  	  	  	  	 When v.Data_Type_Id = 8  Then 'String'
 	  	  	  	  	  	 When v.Data_Type_Id > 50 Then 'String'
 	  	  	  	  	  	 Else 'Other' 
 	  	  	  	  	 End 
 	  	  	  	  	 From Variables_Base v
 	  	  	  	  	 Join Prod_Units u on (u.PU_Id = v.PU_Id) and (u.PU_Id > 0)
 	  	  	  	  	 Join Prod_Lines l on (l.PL_Id = u.PL_Id)
 	  	  	  	  	 Where 
 	  	  	  	  	  	 REPLACE(REPLACE(REPLACE(l.PL_Desc,'.',''),' ',''),';','') Like '%' + @lineName + '%' AND
 	  	  	  	  	  	 REPLACE(REPLACE(REPLACE(u.PU_Desc,'.',''),' ',''),';','') Like '%' + @unitName + '%' AND
 	  	  	  	  	  	 REPLACE(REPLACE(REPLACE(v.Var_Desc,'.',''),' ',''),';','') Like '%' + @variableName + '%' AND
 	  	  	  	  	  	 REPLACE(REPLACE(REPLACE(l.PL_Desc,'.',''),' ',''),';','') + '.' + 
 	  	  	  	  	  	 REPLACE(REPLACE(REPLACE(u.PU_Desc,'.',''),' ',''),';','') + '.' + 
 	  	  	  	  	  	 REPLACE(REPLACE(REPLACE(v.Var_Desc,'.',''),' ',''),';','')
 	  	  	  	  	  	 Like '%' + @VarIdMask + '%'
 	  	  	  	  	 ORDER BY Full_Tag
 	  	  	 End
 	  	 Else
 	  	  	 Begin
 	  	  	  	 Select 
 	  	  	  	  	 Full_Tag = REPLACE(REPLACE(REPLACE(l.PL_Desc,'.',''),' ',''),';','') + '.' + 
 	  	  	  	  	  	  	  	  	  	  	  	  REPLACE(REPLACE(REPLACE(u.PU_Desc,'.',''),' ',''),';','') + '.' + 
 	  	  	  	  	  	  	  	  	  	  	  	  REPLACE(REPLACE(REPLACE(v.Var_Desc,'.',''),' ',''),';',''),
 	  	  	  	  	 v.Var_Desc,
 	  	  	  	  	 v.Eng_Units,
 	  	  	  	  	 DataType = Case 
 	  	  	  	  	  	 When v.Data_Type_Id = 1  Then 'Integer' 
 	  	  	  	  	  	 When v.Data_Type_Id = 2  Then 'Float'
 	  	  	  	  	  	 When v.Data_Type_Id = 3  Then 'String'
 	  	  	  	  	  	 When v.Data_Type_Id = 4  Then 'Integer'
 	  	  	  	  	  	 When v.Data_Type_Id = 6  Then 'Integer'
 	  	  	  	  	  	 When v.Data_Type_Id = 7  Then 'Float'
 	  	  	  	  	  	 When v.Data_Type_Id = 8  Then 'String'
 	  	  	  	  	  	 When v.Data_Type_Id > 50 Then 'String'
 	  	  	  	  	  	 Else 'Other' 
 	  	  	  	  	 End 
 	  	  	  	  	 From Variables_Base v
 	  	  	  	  	 Join Prod_Units u on (u.PU_Id = v.PU_Id) and (u.PU_Id > 0)
 	  	  	  	  	 Join Prod_Lines l on (l.PL_Id = u.PL_Id)
 	  	  	  	  	 Where 
 	  	  	  	  	  	 REPLACE(REPLACE(REPLACE(l.PL_Desc,'.',''),' ',''),';','') + '.' + 
 	  	  	  	  	  	 REPLACE(REPLACE(REPLACE(u.PU_Desc,'.',''),' ',''),';','') + '.' + 
 	  	  	  	  	  	 REPLACE(REPLACE(REPLACE(v.Var_Desc,'.',''),' ',''),';','')
 	  	  	  	  	  	 Like '%' + @VarIdMask + '%'
 	  	  	  	  	 ORDER BY Full_Tag
 	  	  	 End
  End
Set NoCount OFF
