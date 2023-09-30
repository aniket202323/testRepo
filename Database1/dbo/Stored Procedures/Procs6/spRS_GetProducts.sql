CREATE PROCEDURE dbo.spRS_GetProducts
@ProductGroup int = Null, 
@Order int = 0,
@STime datetime = Null,
@ETime datetime = Null,
@Exclude_String varchar(7900) = Null,
@PU_Id int = Null, 
@Mask_String varchar(25) = Null,
@Mask_Key int = null,
@SelectedVariables varchar(1000) = Null,
@InTimeZone varchar(200) = NULL
 AS 
SELECT @PU_Id = coalesce(master_Unit,@PU_Id) From Prod_Units where PU_Id = @PU_Id
SELECT @STime =  dbo.fnServer_CmnConvertToDBTime(@STime,@InTimeZone)
SELECT @ETime = dbo.fnServer_CmnConvertToDBTime(@ETime,@InTimeZone)  	  
  	  
 Declare @SelectedProdUnits varchar(1000)
Create Table #SelectedVariables(Id int, Var_Id int, PU_ID int)
If @SelectedVariables Is Not NULL
  Begin
  	  
    Insert Into #SelectedVariables(ID, Var_Id) Exec spRS_MakeOrderedResultSet @SelectedVariables
    update #SelectedVariables  Set PU_Id = coalesce(u.Master_Unit,u.PU_Id) 
     from #SelectedVariables sv 
      Join Variables v on v.var_Id = sv.Var_Id
      Join Prod_Units u on v.PU_Id = u.PU_Id
    Exec spRS_MakeStringFromQueryResults 'SELECT PU_ID FROM #SelectedVariables', @SelectedProdUnits output
  End
Declare @SQLStr varchar(8000)
Declare @Mask varchar(50)
Declare @Exclude varchar(7900)
If @Exclude_String Is Null
  Select @Exclude = '1'
Else
  Begin
    If LTrim(@Exclude_String) = ''
      Select @Exclude = '1'
    Else
      Select @Exclude = '1,' + @Exclude_String
  End
----------------------------
-- Setup Search Mask
----------------------------
If @Mask_Key Is Null
  Select @Mask_Key = 2
If @Mask_String Is Null
  Select @Mask = '%'
Else
  Begin
    If LTrim(@Mask_String) = ''
      Select @Mask = '%'
    Else
      Begin
  	    	  --Begins With
  	    	  If @Mask_Key = 1
  	    	    	  Select @Mask = @Mask_String + '%'
  	    	  --Contains
  	    	  If @Mask_Key = 2
  	    	    	  Select @Mask = '%' + @Mask_String + '%'
  	    	  --Ends With
  	    	  If @Mask_Key = 3
  	    	    	  Select @Mask = '%' + @Mask_String 
      End
  End
----------------------------
-- Show All Products
----------------------------
If @ProductGroup Is Null
  Begin
    SELECT * FROM Products PR WHERE PR.Prod_Id > 1 Order By PR.Prod_Code
  End
----------------------------
-- Apply Search Criteria
----------------------------
Else
  Begin
  	  ----------------------------
  	  -- All Products
  	  ----------------------------
    If @ProductGroup = -2 
      Begin
  	    	  select @Mask = '''' + @Mask + ''''
  	    	  -- Prod_Code or Prod_Desc
  	    	  If @Order = 0 
  	            Select @SQLStr = 'SELECT PP.Prod_Id, PP.Prod_Desc FROM Products PP Where (Prod_Desc Like ' + @Mask + ' or Prod_Code Like ' + @Mask + ')'
  	    	  Else
  	            Select @SQLStr = 'SELECT PP.Prod_Id, PP.Prod_Code FROM Products PP Where (Prod_Desc Like ' + @Mask + ' or Prod_Code Like ' + @Mask + ')'
  	    	  -- Exclude Some Variables?
  	    	  If @Exclude Is Not Null
  	    	    	  Select @SQLStr = @SQLStr + ' And PP.Prod_Id Not In (' + @Exclude + ')'
  	    	  -- Filter By Selected Variables
  	  
  	    	  If @SelectedVariables Is Not NULL
  	    	  Begin
  	            Select @SQLStr = Replace(@SQLStr, 'FROM Products PP',  ' FROM Products PP Join PU_Products PUP on PP.Prod_Id = PUP.Prod_Id  and PUP.PU_Id In (' + @SelectedProdUnits + ') ')
  	    	  End
  	    	    	  -- Filter By Unit
  	    	  Else If @PU_Id Is Not Null
  	    	    	  Begin
  	    	    	    	  Select @SQLStr = Replace(@SQLStr, 'FROM Products PP',  ' FROM Products PP Join PU_Products PUP on PP.Prod_Id = PUP.Prod_Id  and PUP.PU_Id = ' + Convert(VarChar(5), @PU_Id))
  	    	    	  End
  	  
  	    	  Select @SQLStr = @SQLStr + ' Order By PP.Prod_Desc'
  	    	  Select @SQLStr = Replace(@SQLStr, '@ProductGroup', @ProductGroup)
  	    	  --Print @SQLStr
  	    	  Exec(@SQLStr)
      End
  	  ----------------------------
  	  -- Products Run
  	  ----------------------------
    Else If @ProductGroup = -1 
      Begin
  	    	  ------------------------------------------------
  	    	  -- If the End Time is before the Start Time Then
  	    	  -- Set the End Time = Now
  	    	  ------------------------------------------------
  	    	  
  	    	  If @ETime < @STime Select @ETime = GetDate()
        CREATE TABLE #Changes (Prod_Id integer)
        If @PU_Id Is Null
  	    	    	  Begin
  	    	    	    	  If @SelectedVariables Is NULL 
  	    	    	    	    Begin
  	    	    	    	    	  INSERT INTO #Changes
  	    	    	    	    	    	  SELECT PS.prod_id
  	    	    	    	    	    	  FROM production_starts  PS
  	    	    	    	    	    	  Join Products P on P.Prod_Id = PS.Prod_Id
  	    	    	    	    	    	  WHERE  
  	    	    	    	    	    	    P.Prod_Id <> 1 AND
  	    	    	    	    	    	    (Prod_Desc like @Mask OR Prod_Code Like @Mask) AND
  	    	    	    	    	    	   ((Start_Time <= @STime AND End_Time IS Null) OR
  	    	    	    	    	    	    (Start_Time <= @STime AND End_Time > @STime) OR
  	    	    	    	    	    	    (Start_Time > @STime AND End_Time < @ETime) OR
  	    	    	    	    	    	    (Start_Time > @STime AND Start_Time < @ETime))
  	    	    	    	    	  Insert Into #Changes
  	    	    	    	    	    	  Select distinct Applied_Product
  	    	    	    	    	    	  From Events
  	    	    	    	    	    	  Where Applied_Product is not null
  	    	    	    	    	    	  and Applied_Product <> 1
  	    	    	    	    	    	  and Timestamp > @STime and timestamp <= @ETime
  	    	    	    	    End
  	    	    	    	  Else
  	    	    	    	    Begin
  	    	    	    	    	  INSERT INTO #Changes
  	    	    	    	    	    	  SELECT PS.prod_id
  	    	    	    	    	    	  FROM production_starts  PS
  	    	    	    	    	    	  Join Products P on P.Prod_Id = PS.Prod_Id
  	    	    	    	    	    	  Join #SelectedVariables v on v.PU_ID = ps.PU_Id
  	    	    	    	    	    	  WHERE  
  	    	    	    	    	    	    P.Prod_Id <> 1 AND
  	    	    	    	    	    	    (Prod_Desc like @Mask OR Prod_Code Like @Mask) AND
  	    	    	    	    	    	   ((Start_Time <= @STime AND End_Time IS Null) OR
  	    	    	    	    	    	    (Start_Time <= @STime AND End_Time > @STime) OR
  	    	    	    	    	    	    (Start_Time > @STime AND End_Time < @ETime) OR
  	    	    	    	    	    	    (Start_Time > @STime AND Start_Time < @ETime))
  	    	    	    	    	  Insert Into #Changes
  	    	    	    	    	    	  Select distinct Applied_Product
  	    	    	    	    	    	  From Events e
  	    	    	    	    	    	  Join #SelectedVariables v on v.PU_ID = e.PU_Id
  	    	    	    	    	    	  Where Applied_Product is not null
  	    	    	    	    	    	  and Applied_Product <> 1
  	    	    	    	    	    	  and Timestamp > @STime and timestamp <= @ETime
  	    	    	    	    End
  	    	    	  End -- IF PU_ID Is NULL
  	    	    -----------------------------
  	    	    -- Filter By Production Unit
  	    	    -----------------------------
  	    	  Else -- @PU_Id is not null
  	    	    Begin
            INSERT INTO #Changes
            SELECT PS.prod_id
            FROM production_starts  PS
  	    	    	  Join Products P on P.Prod_Id = PS.Prod_Id
            WHERE  
  	    	        P.Prod_Id <> 1 AND
  	    	        PU_Id = @PU_Id AND
  	    	    	   (Prod_Desc like @Mask OR Prod_Code Like @Mask) AND
             ((Start_Time <= @STime AND End_Time IS Null) OR
              (Start_Time <= @STime AND End_Time > @STime) OR
              (Start_Time > @STime AND End_Time < @ETime) OR
              (Start_Time > @STime AND Start_Time < @ETime))  	    	    
  	    	    	  Insert Into #Changes
  	    	    	    	  Select distinct Applied_Product
  	    	    	    	  From Events
  	    	    	    	  Where Applied_Product is not null
  	    	    	    	  and Applied_Product <> 1
  	    	    	    	  and PU_ID = @PU_ID
  	    	    	    	  and Timestamp > @STime and timestamp <= @ETime
  	    	    End
  	    	  If @Order = 0
  	            If @Exclude Is Null
  	              Select @SQLStr = 'SELECT DISTINCT CG.Prod_Id, PR.prod_desc, PR.prod_code FROM #Changes CG JOIN Products PR ON CG.prod_id = PR.prod_id ORDER BY PR.prod_code'
  	            Else
  	              Select @SQLStr = 'SELECT DISTINCT CG.Prod_Id, PR.prod_desc, PR.prod_code FROM #Changes CG JOIN Products PR ON CG.prod_id = PR.prod_id Where CG.Prod_Id not in (' + @Exclude + ') ORDER BY PR.prod_code'
  	    	  Else
  	            If @Exclude Is Null
  	              Select @SQLStr = 'SELECT DISTINCT CG.Prod_Id, PR.prod_code FROM #Changes CG JOIN Products PR ON CG.prod_id = PR.prod_id ORDER BY PR.prod_code'
  	            Else
  	              Select @SQLStr = 'SELECT DISTINCT CG.Prod_Id, PR.prod_code FROM #Changes CG JOIN Products PR ON CG.prod_id = PR.prod_id Where CG.Prod_Id not in (' + @Exclude + ') ORDER BY PR.prod_code'
  	  
  	    	  Select @SQLStr = Replace(@SQLStr, '@ProductGroup', @ProductGroup)
  	    	  Exec(@SQLStr)
  	          DROP TABLE #Changes
      End --If @ProductGroup = -1 
  	  --------------------------
  	  -- Any Product
  	  --------------------------
    Else If @ProductGroup = 0 
      Begin
        If @Order = 0 
          Select 0 'Prod_Id', '[Any Product]' 'Prod_Desc'
  	    	  Else
          Select 0 'Prod_Id', '[Any Product]' 'Prod_Code'
      End
  	  ----------------------------------------
  	  -- Products From This Production Group
  	  ----------------------------------------
    Else
      Begin 
        If @Order = 0 
  	    	    If @Exclude Is Null
            Select @SQLStr = 'SELECT PP.Prod_Id, PP.Prod_Desc, PP.Prod_Code FROM Products PP JOIN Product_Group_Data PD ON PP.prod_id = PD.prod_id AND PD.product_grp_id = @ProductGroup Order By PP.Prod_Code'
          Else
            Select @SQLStr = 'SELECT PP.Prod_Id, PP.Prod_Desc, PP.Prod_Code FROM Products PP JOIN Product_Group_Data PD ON PP.prod_id = PD.prod_id AND PD.product_grp_id = @ProductGroup AND PD.Prod_Id not in (' + @Exclude + ') Order By PP.Prod_Code'
        Else
          If @Exclude Is Null
            Select @SQLStr = 'SELECT PP.Prod_Id, PP.Prod_Code FROM Products PP JOIN Product_Group_Data PD ON PP.prod_id = PD.prod_id AND PD.product_grp_id = @ProductGroup Order By PP.Prod_Code'
          Else
            Select @SQLStr = 'SELECT PP.Prod_Id, PP.Prod_Code FROM Products PP JOIN Product_Group_Data PD ON PP.prod_id = PD.prod_id AND PD.product_grp_id = @ProductGroup AND PD.Prod_Id not in (' + @Exclude + ') Order By PP.Prod_Code'
  	    	  Select @SQLStr = Replace(@SQLStr, '@ProductGroup', @ProductGroup)
  	    	  Exec(@SQLStr)
      End
  End
Drop Table #SelectedVariables
