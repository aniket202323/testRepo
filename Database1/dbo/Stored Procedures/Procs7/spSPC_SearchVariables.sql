Create Procedure dbo.spSPC_SearchVariables
@Line int,
@Unit int,
@ChildUnit int,
@Group int,
@SearchText nvarchar(100)
AS
If @Unit Is Null 
  Begin
    -- We Have Specified Only To The Line Level
    If @SearchText Is Null 
      Begin
        Select Id = v.Var_Id,
               Description = v.Var_Desc, 
               VariableType = Case 
                                When  v.Data_Type_Id > 50 Then 'Attribute'
                                When  v.Data_Type_Id  = 3 Then 'Attribute'
                                When  v.Data_Type_Id  = 5 Then 'Attribute'
                                Else 'Variable'
                              End, 
               EventType = et.ET_Desc, Unit = p.PU_Desc, DataSource = ds.DS_Desc,
               Var_Precision = Coalesce(v.Var_Precision,0) 
          From Variables v
          Join Event_Types et on et.ET_Id = v.Event_Type
          Join Prod_Units p on p.PU_Id = v.PU_Id and p.PL_Id = @Line
          Join Data_Source ds on ds.DS_Id = v.DS_Id
          Order By v.Var_Desc
      End
    Else
      Begin
        Select Id = v.Var_Id,
               Description = v.Var_Desc, 
               VariableType = Case 
                                When  v.Data_Type_Id > 50 Then 'Attribute'
                                When  v.Data_Type_Id  = 3 Then 'Attribute'
                                When  v.Data_Type_Id  = 5 Then 'Attribute'
                                Else 'Variable'
                              End, 
               EventType = et.ET_Desc, Unit = p.PU_Desc, DataSource = ds.DS_Desc,
               Var_Precision = Coalesce(v.Var_Precision,0) 
          From Variables v
          Join Event_Types et on et.ET_Id = v.Event_Type
          Join Prod_Units p on p.PU_Id = v.PU_Id and p.PL_Id = @Line
          Join Data_Source ds on ds.DS_Id = v.DS_Id
          Where v.Var_Desc Like '%' + @SearchText + '%'
          Order By v.Var_Desc
      End
  End
Else If @ChildUnit Is Null
  Begin
    -- We Have Specified To The Master Unit Level
    If @SearchText Is Null 
      Begin
        Select Id = v.Var_Id,
               Description = v.Var_Desc, 
               VariableType = Case 
                                When  v.Data_Type_Id > 50 Then 'Attribute'
                                When  v.Data_Type_Id  = 3 Then 'Attribute'
                                When  v.Data_Type_Id  = 5 Then 'Attribute'
                                Else 'Variable'
                              End, 
               EventType = et.ET_Desc, Unit = p.PU_Desc, DataSource = ds.DS_Desc, 
               Var_Precision = Coalesce(v.Var_Precision,0)
          From Variables v
          Join Event_Types et on et.ET_Id = v.Event_Type
          Join Prod_Units p on p.PU_Id = v.PU_Id and p.PL_Id = @Line and (p.PU_Id = @Unit or p.Master_Unit = @Unit)
          Join Data_Source ds on ds.DS_Id = v.DS_Id
          Order By v.Var_Desc
      End
    Else
      Begin
        Select Id = v.Var_Id,
               Description = v.Var_Desc, 
               VariableType = Case 
                                When  v.Data_Type_Id > 50 Then 'Attribute'
                                When  v.Data_Type_Id  = 3 Then 'Attribute'
                                When  v.Data_Type_Id  = 5 Then 'Attribute'
                                Else 'Variable'
                              End, 
               EventType = et.ET_Desc, Unit = p.PU_Desc, DataSource = ds.DS_Desc,
               Var_Precision = Coalesce(v.Var_Precision,0) 
          From Variables v
          Join Event_Types et on et.ET_Id = v.Event_Type
          Join Prod_Units p on p.PU_Id = v.PU_Id and p.PL_Id = @Line and (p.PU_Id = @Unit or p.Master_Unit = @Unit)
          Join Data_Source ds on ds.DS_Id = v.DS_Id
          Where v.Var_Desc Like '%' + @SearchText + '%'
          Order By v.Var_Desc
      End
  End
Else If @Group Is Null
  Begin
    -- We Have Specified To The Child Unit Level
    If @SearchText Is Null 
      Begin
        Select Id = v.Var_Id,
               Description = v.Var_Desc, 
               VariableType = Case 
                                When  v.Data_Type_Id > 50 Then 'Attribute'
                                When  v.Data_Type_Id  = 3 Then 'Attribute'
                                When  v.Data_Type_Id  = 5 Then 'Attribute'
                                Else 'Variable'
                              End, 
               EventType = et.ET_Desc, Unit = p.PU_Desc, DataSource = ds.DS_Desc,
               Var_Precision = Coalesce(v.Var_Precision,0) 
          From Variables v
          Join Event_Types et on et.ET_Id = v.Event_Type
          Join Prod_Units p on p.PU_Id = v.PU_Id 
          Join Data_Source ds on ds.DS_Id = v.DS_Id
          Where v.PU_Id = @ChildUnit
          Order By v.Var_Desc
      End
    Else
      Begin
        Select Id = v.Var_Id,
               Description = v.Var_Desc, 
               VariableType = Case 
                                When  v.Data_Type_Id > 50 Then 'Attribute'
                                When  v.Data_Type_Id  = 3 Then 'Attribute'
                                When  v.Data_Type_Id  = 5 Then 'Attribute'
                                Else 'Variable'
                              End, 
               EventType = et.ET_Desc, Unit = p.PU_Desc, DataSource = ds.DS_Desc, 
               Var_Precision = Coalesce(v.Var_Precision,0)
          From Variables v
          Join Event_Types et on et.ET_Id = v.Event_Type
          Join Prod_Units p on p.PU_Id = v.PU_Id 
          Join Data_Source ds on ds.DS_Id = v.DS_Id
          Where v.PU_Id = @ChildUnit and v.Var_Desc Like '%' + @SearchText + '%'
          Order By v.Var_Desc
      End
  End
Else
  Begin
    -- We Have Specified All The Way To The Group Level
    If @SearchText Is Null 
      Begin
        Select Id = v.Var_Id,
               Description = v.Var_Desc, 
               VariableType = Case 
                                When  v.Data_Type_Id > 50 Then 'Attribute'
                                When  v.Data_Type_Id  = 3 Then 'Attribute'
                                When  v.Data_Type_Id  = 5 Then 'Attribute'
                                Else 'Variable'
                              End, 
               EventType = et.ET_Desc, Unit = p.PU_Desc, DataSource = ds.DS_Desc, 
               Var_Precision = Coalesce(v.Var_Precision,0)
          From Variables v
          Join Event_Types et on et.ET_Id = v.Event_Type
          Join Prod_Units p on p.PU_Id = v.PU_Id 
          Join Data_Source ds on ds.DS_Id = v.DS_Id
          Where v.PU_Id = @ChildUnit and v.PUG_Id = @Group
          Order By v.Var_Desc
      End
    Else
      Begin
        Select Id = v.Var_Id,
               Description = v.Var_Desc, 
               VariableType = Case 
                                When  v.Data_Type_Id > 50 Then 'Attribute'
                                When  v.Data_Type_Id  = 3 Then 'Attribute'
                                When  v.Data_Type_Id  = 5 Then 'Attribute'
                                Else 'Variable'
                              End, 
               EventType = et.ET_Desc, Unit = p.PU_Desc, DataSource = ds.DS_Desc,
               Var_Precision = Coalesce(v.Var_Precision,0) 
          From Variables v
          Join Event_Types et on et.ET_Id = v.Event_Type
          Join Prod_Units p on p.PU_Id = v.PU_Id 
          Join Data_Source ds on ds.DS_Id = v.DS_Id
          Where v.PU_Id = @ChildUnit and v.PUG_Id = @Group and v.Var_Desc Like '%' + @SearchText + '%'
          Order By v.Var_Desc
      End
  End
