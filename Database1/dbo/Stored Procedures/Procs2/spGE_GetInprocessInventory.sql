CREATE Procedure dbo.spGE_GetInprocessInventory
@PEI_Id int,
@Sheet_Id Int = null,
@ClientVersion int = 3,
@SortOrder 	  	 nvarchar(20) = '',
@RetrieveAll 	 Int = 1,
@LanguageId int = 0
AS
Declare @OverRideLId 	 Int
DECLARE @Timestamp 	  	 Datetime,
 	 @PU_Id 	  	  	 Int,
 	 @Alt_Spec 	  	 Int,
 	 @Prim_Spec 	  	 Int,
 	 @PathAlt_Spec 	 Int,
 	 @PathPrim_Spec 	 Int,
 	 @CurrentProduct 	  	 Int,
 	 @Primary_Prod_Code 	 nvarchar(25),
 	 @Alternate_Prod_Code 	 nvarchar(25),
 	 @Prod_Id 	  	 Int,
 	 @PC 	  	  	 nvarchar(25),
 	 @AppliedProdId 	  	 Int,
 	 @Prop_Id 	  	 Int,
 	 @Now 	  	  	 DateTime,
 	 @Char_Id 	  	 Int,
 	 @ATitle 	  	  	 nvarchar(50),
 	 @XTitle 	  	  	 nvarchar(50),
 	 @YTitle 	  	  	 nvarchar(50),
 	 @ZTitle 	  	  	 nvarchar(50),
 	 @AEnabled 	  	 TinyInt,
 	 @YEnabled 	  	 TinyInt,
 	 @ZEnabled 	  	 TinyInt,
 	 @SqlStmt 	  	 nvarchar(1000),
 	 @Sql1 	  	  	 nVarChar(3500),
 	 @MaxDays 	  	 Int,
 	 @MaxRows 	  	 Int,
 	 @CareAboutProd 	 Int
SELECT @CareAboutProd = 0
SELECT @Now = dbo.fnServer_CmnGetDate(GetUTCdate())
IF @Sheet_Id Is Not Null
BEGIN
 	 SELECT @MaxDays = Max_Inventory_Days FROM Sheets WHERE sheet_Id = @Sheet_Id
 	 SELECT @MaxRows = convert(Int,[Value])
 	 FROM Sheet_Display_Options
 	 WHERE Sheet_Id = @Sheet_Id and Display_Option_Id = 412
END
If @RetrieveAll is null
 	 SET @RetrieveAll = 1
IF @SortOrder Is Null or @SortOrder = ''
 	 SELECT @SortOrder = '4 ASC'
ELSE
BEGIN
 	 SET @SortOrder = RIGHT(@SortOrder,LEN(@SortOrder) -1)
 	 SET @SortOrder = Left(@SortOrder,LEN(@SortOrder) -1)
 	 SELECT @SortOrder = REPLACE(@SortOrder,'|',',')
 	 SELECT @SortOrder = REPLACE(@SortOrder,'A',' ASC')
 	 SELECT @SortOrder = REPLACE(@SortOrder,'D',' DESC')
END
If @MaxDays = 0 SELECT @MaxDays = 365
If @MaxDays is null SELECT @MaxDays = 365
IF @MaxRows Is Null  or @RetrieveAll = 1
 	 SET @MaxRows = 0
Declare @PathId Int
SELECT @PathId = Null
SELECT  	 @ATitle 	 = Coalesce(Dimension_A_Name,'N/A'),
 	 @XTitle = Coalesce(Dimension_X_Name,'N/A'),
 	 @YTitle = Coalesce(Dimension_Y_Name,'N/A'),
 	 @ZTitle = Coalesce(Dimension_Z_Name,'N/A'),
 	 @AEnabled = Coalesce(Dimension_A_Enabled,0),
 	 @YEnabled = Coalesce(Dimension_Y_Enabled,0),
 	 @ZEnabled = Coalesce(Dimension_Z_Enabled,0),
 	 @PU_Id = PU_Id,
 	 @Alt_Spec = Alternate_Spec_Id,
 	 @Prim_Spec = Primary_Spec_Id
 FROM prdExec_Inputs pei
 Join Event_subtypes es ON es.Event_Subtype_Id = pei.Event_Subtype_Id
 WHERE PEI_Id =  @PEI_Id
If ltrim(rtrim(@XTitle)) = '' or ltrim(rtrim(@XTitle)) is null 
   SELECT @XTitle = 'N/A'
If ltrim(rtrim(@ATitle)) = '' or ltrim(rtrim(@ATitle)) is null 
   SELECT @ATitle = 'N/A'
If ltrim(rtrim(@YTitle)) = '' or ltrim(rtrim(@YTitle)) is null 
   SELECT @YTitle = 'N/A'
If ltrim(rtrim(@ZTitle)) = '' or ltrim(rtrim(@ZTitle)) is null 
   SELECT @ZTitle = 'N/A'
If @ClientVersion = 4 
 	 SELECT @XTitle = @XTitle + Char(2) +  '2',@YTitle = @YTitle + Char(2) +  '2',@ZTitle = @ZTitle + Char(2) +  '2',@ATitle = @ATitle + Char(2) +  '2'
SELECT @PathId = Path_Id FROM Prdexec_Path_Unit_Starts WHERE PU_Id = @Pu_Id and End_Time is null
If @PathId is Not null
  Begin 
 	 SELECT @PathAlt_Spec = Null,@PathPrim_Spec = Null
 	 SELECT @PathAlt_Spec = Alternate_Spec_Id,@PathPrim_Spec = Primary_Spec_Id
   	 FROM PrdExec_Path_Inputs
   	 WHERE Path_Id  = @PathId
  End
If @LanguageId Is Null
 	 SET @LanguageId = 0
SET @OverRideLId = -(@LanguageId + 1)
DECLARE
        @Col4                   nvarchar(50),
        @Col5                   nvarchar(50),
        @Col6                   nvarchar(50), 
        @Col7                   nvarchar(50),
        @Col8                   nvarchar(50),
        @Col9                   nvarchar(50),         
 	  	 @Col10                  nvarchar(50),
 	  	 @Col11                  nvarchar(50),         
 	  	 @Col12                  nvarchar(50),         
        @Col13                  nvarchar(50)        
--If Required Prompt is not found, substitute the English prompt
SELECT @Col4 = coalesce(ld1.Prompt_String,ld2.Prompt_String, ld.Prompt_String) 
 	 FROM Language_Data ld 
 	 Left Join Language_Data ld1 ON ld1.Prompt_Number = ld.Prompt_Number and ld1.Language_Id = @OverRideLId
 	 Left Join Language_Data ld2 ON ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @LanguageId
 	 WHERE ld.Language_Id = 0 and ld.Prompt_Number = 24107
SELECT @Col4 = coalesce(@Col4,dbo.fnDBTranslate(N'0',24107,'Event'))
SELECT @Col5 = coalesce(ld1.Prompt_String,ld2.Prompt_String, ld.Prompt_String)
 	 FROM Language_Data ld 
 	 Left Join Language_Data ld1 ON ld1.Prompt_Number = ld.Prompt_Number and ld1.Language_Id = @OverRideLId
 	 Left Join Language_Data ld2 ON ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @LanguageId
 	 WHERE ld.Language_Id = 0 and ld.Prompt_Number = 24061
SELECT @Col5 = coalesce(@Col5,dbo.fnDBTranslate(N'0',24061,'Status'))
SELECT @Col6 = coalesce(ld1.Prompt_String,ld2.Prompt_String, ld.Prompt_String)
 	 FROM Language_Data ld 
 	 Left Join Language_Data ld1 ON ld1.Prompt_Number = ld.Prompt_Number and ld1.Language_Id = @OverRideLId
 	 Left Join Language_Data ld2 ON ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @LanguageId
 	 WHERE ld.Language_Id = 0 and ld.Prompt_Number = 24108
SELECT @Col6 = coalesce(@Col6,dbo.fnDBTranslate(N'0',24108,'Product'))
SELECT @Col7 = coalesce(ld1.Prompt_String,ld2.Prompt_String, ld.Prompt_String)
 	 FROM Language_Data ld 
 	 Left Join Language_Data ld1 ON ld1.Prompt_Number = ld.Prompt_Number and ld1.Language_Id = @OverRideLId
 	 Left Join Language_Data ld2 ON ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @LanguageId
 	 WHERE ld.Language_Id = 0 and ld.Prompt_Number = 24105
SELECT @Col7 = coalesce(@Col7,dbo.fnDBTranslate(N'0',24105,'Time'))
SELECT @Col8 = coalesce(ld1.Prompt_String,ld2.Prompt_String, ld.Prompt_String)
 	 FROM Language_Data ld 
 	 Left Join Language_Data ld1 ON ld1.Prompt_Number = ld.Prompt_Number and ld1.Language_Id = @OverRideLId
 	 Left Join Language_Data ld2 ON ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @LanguageId
 	 WHERE ld.Language_Id = 0 and ld.Prompt_Number = 24109
SELECT @Col8 = coalesce(@Col8,dbo.fnDBTranslate(N'0',24109,'Age'))
SELECT @Col9 = coalesce(ld1.Prompt_String,ld2.Prompt_String, ld.Prompt_String)
 	 FROM Language_Data ld 
 	 Left Join Language_Data ld1 ON ld1.Prompt_Number = ld.Prompt_Number and ld1.Language_Id = @OverRideLId
 	 Left Join Language_Data ld2 ON ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @LanguageId
 	 WHERE ld.Language_Id = 0 and ld.Prompt_Number = 24138
SELECT @Col9 = coalesce(@Col9,dbo.fnDBTranslate(N'0',24138,'DimX'))
SELECT @Col10 = coalesce(ld1.Prompt_String,ld2.Prompt_String, ld.Prompt_String)
 	 FROM Language_Data ld 
 	 Left Join Language_Data ld1 ON ld1.Prompt_Number = ld.Prompt_Number and ld1.Language_Id = @OverRideLId
 	 Left Join Language_Data ld2 ON ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @LanguageId
 	 WHERE ld.Language_Id = 0 and ld.Prompt_Number = 24135
SELECT @Col10 = coalesce(@Col10,dbo.fnDBTranslate(N'0',24135,'DimY'))
SELECT @Col11 = coalesce(ld1.Prompt_String,ld2.Prompt_String, ld.Prompt_String)
 	 FROM Language_Data ld 
 	 Left Join Language_Data ld1 ON ld1.Prompt_Number = ld.Prompt_Number and ld1.Language_Id = @OverRideLId
 	 Left Join Language_Data ld2 ON ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @LanguageId
 	 WHERE ld.Language_Id = 0 and ld.Prompt_Number = 24136
SELECT @Col11 = coalesce(@Col11,dbo.fnDBTranslate(N'0',24136,'DimZ'))
SELECT @Col12 = coalesce(ld1.Prompt_String,ld2.Prompt_String, ld.Prompt_String)
 	 FROM Language_Data ld 
 	 Left Join Language_Data ld1 ON ld1.Prompt_Number = ld.Prompt_Number and ld1.Language_Id = @OverRideLId
 	 Left Join Language_Data ld2 ON ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @LanguageId
 	 WHERE ld.Language_Id = 0 and ld.Prompt_Number = 24137
SELECT @Col12 = coalesce(@Col12,dbo.fnDBTranslate(N'0',24137,'DimA'))
SELECT @Col13 = coalesce(ld1.Prompt_String,ld2.Prompt_String, ld.Prompt_String)
 	 FROM Language_Data ld 
 	 Left Join Language_Data ld1 ON ld1.Prompt_Number = ld.Prompt_Number and ld1.Language_Id = @OverRideLId
 	 Left Join Language_Data ld2 ON ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @LanguageId
 	 WHERE ld.Language_Id = 0 and ld.Prompt_Number = 24223
SELECT @Col13 = coalesce(@Col13,dbo.fnDBTranslate(N'0',24223,'Location'))
SELECT @Alt_Spec = Coalesce(@PathAlt_Spec,@Alt_Spec)
SELECT @Prim_Spec = Coalesce(@PathPrim_Spec,@Prim_Spec)
SELECT @CurrentProduct = Prod_Id 
  FROM Production_Starts
  WHERE PU_Id = @PU_Id and (Start_Time <= @Now and  (End_time > @Now or  End_time is null))
If @Prim_Spec is not null
 Begin
   SET @CareAboutProd = 1
   SELECT @Prop_Id = Prop_Id
     FROM Specifications
     WHERE Spec_Id = @Prim_Spec 
   SELECT @Char_Id = Null
   SELECT @Char_Id = Char_Id
     FROM  PU_Characteristics
     WHERE PU_Id  = @PU_Id And Prop_Id = @Prop_Id and Prod_Id = @CurrentProduct
   If @Char_Id is Null
     SELECT @Primary_Prod_Code = Null
   Else
     SELECT @Primary_Prod_Code = Target
      FROM Active_Specs
      WHERE Spec_Id  = @Prim_Spec and  Char_Id = @Char_Id
      and (Effective_Date < @Now and (Expiration_Date is null or Expiration_Date > @Now))
 End
else
  SELECT @Primary_Prod_Code = Null
If @Alt_Spec is not null
 Begin
 	 SET @CareAboutProd = 1
   SELECT @Prop_Id = Prop_Id
     FROM Specifications
     WHERE Spec_Id = @Alt_Spec 
   SELECT @Char_Id = Null
   SELECT @Char_Id = Char_Id
     FROM  PU_Characteristics
     WHERE PU_Id  = @PU_Id And Prop_Id = @Prop_Id and Prod_Id = @CurrentProduct
   If @Char_Id is null 
     SELECT @Alternate_Prod_Code = Null
   Else
     SELECT @Alternate_Prod_Code = Target
      FROM Active_Specs
      WHERE Spec_Id  = @Alt_Spec and  Char_Id = @Char_Id
      and (Effective_Date < @Now and (Expiration_Date is null or Expiration_Date > @Now))
 End
else
  SELECT @Alternate_Prod_Code = Null
If @CurrentProduct = 1 
  Begin
 	 SET @CareAboutProd = 0
    SELECT @Alternate_Prod_Code = Null
    SELECT @Primary_Prod_Code = Null
  End
IF @CareAboutProd = 0
BEGIN
 	 IF CharIndex('6',@SortOrder,1) > 0 
 	  	 SET @CareAboutProd = 1
END
 Create Table #Output (Event_Id int,Icon_Id Int,PU_Id Int,EventNum nvarchar(50),EventStatus nvarchar(25),Product nvarchar(25) null ,Time DateTime,Age Int,DimX Float NULL,DimY Float NULL,DimZ Float NUll,DimA Float NULL,Applied_Product Int Null,Location nvarchar(50) Null)
IF @CareAboutProd = 1 or @ClientVersion = 3
   Insert Into #Output(Event_Id,EventNum,EventStatus ,Time,Pu_Id,Icon_Id,Age,DimX,DimY,DimZ,DimA,Applied_Product,Location) 
   SELECT Distinct e.Event_Id,Event_num,
          ProdStatus_Desc = case When  PEIP_Id is null then ProdStatus_Desc
                                 Else 'In Progress'
 	  	  	     End,e.Timestamp,
          e.PU_Id,Icon_Id,datediff(minute,e.timestamp,@Now),
          ed.final_dimension_x,ed.final_dimension_y,ed.final_dimension_z,ed.final_dimension_a,e.Applied_Product,pu.Pu_Desc
    FROM  PrdExec_Input_Sources pis
    Join  PrdExec_Input_Source_Data pisd ON pisd.PEIS_Id = pis.PEIS_Id
    Join Events e  ON  pis.PU_Id = e.PU_Id and (e.timestamp between  DateAdd(day,-@MaxDays,@Now)and @Now) and pisd.Valid_Status = e.event_status 
 	 Join Prod_Units pu ON pu.pu_Id = e.pu_Id
    Left Join Event_Details ed ON ed.event_id = e.event_id
    Join  Production_Status p ON p.ProdStatus_Id = e.event_status
    Left Join PrdExec_Input_Event pie ON pie.event_id = e.event_id
    WHERE pis.PEI_Id = @PEI_Id 
 	 Order by e.Timestamp
ELSE
BEGIN
   SET @Sql1 = '   SELECT Distinct e.Event_Id,Icon_Id,e.PU_Id,Event_num,
          ProdStatus_Desc = case When  PEIP_Id is null then ProdStatus_Desc Else ''In Progress'' End,
 	  	   e.Applied_Product,e.Timestamp,datediff(minute,e.timestamp,dbo.fnServer_CmnGetDate(GetUTCdate())),
          ed.final_dimension_x,ed.final_dimension_y,ed.final_dimension_z,ed.final_dimension_a,pu.Pu_Desc
    FROM  PrdExec_Input_Sources pis
    Join  PrdExec_Input_Source_Data pisd ON pisd.PEIS_Id = pis.PEIS_Id
    Join Events e  ON  pis.PU_Id = e.PU_Id and (e.timestamp between  DateAdd(day,-' + Convert(nvarchar(10),@MaxDays) + ',''' + Convert(nvarchar(25),@Now) + ''')and ''' + + Convert(nvarchar(25),@Now) + ''') and pisd.Valid_Status = e.event_status 
 	 Join Prod_Units pu ON pu.pu_Id = e.pu_Id
    Left Join Event_Details ed ON ed.event_id = e.event_id
    Join  Production_Status p ON p.ProdStatus_Id = e.event_status
    Left Join PrdExec_Input_Event pie ON pie.event_id = e.event_id
    WHERE pis.PEI_Id = ' + convert(nvarchar(10),@PEI_Id)
 	 SET @Sql1 = @Sql1 + ' ORDER BY ' + @SortOrder
 	 SET Rowcount @MaxRows
    Insert Into #Output(Event_Id,Icon_Id,Pu_Id,EventNum,EventStatus ,Applied_Product,Time,Age,DimX,DimY,DimZ,DimA,Location) 
 	  	 EXECUTE (@Sql1)
 	 SET Rowcount 0
END
 	 Delete FROM #Output
 	   WHERE Event_Id in (SELECT  Event_Id 
 	  	 FROM PrdExec_Input_Event  pie
 	  	 Join PrdExec_Inputs pis ON pis.pei_Id = Pie.Pei_Id and pis.Lock_Inprogress_Input = 1)
Update #Output  set product =  
(SELECT Prod_code = CASE when #Output.Applied_Product Is null then pp.Prod_code
                    Else
 	  	  	 pp2.Prod_Code
 	  	     End
     FROM Production_Starts s
     Left Join  Products pp ON pp.prod_id = s.prod_id
     Left Join  Products pp2 ON pp2.prod_id = #Output.Applied_Product
     WHERE s.pu_id = #Output.PU_Id and (Start_Time <= #Output.Time and  (s.End_time > #Output.Time or  s.End_time is null)))
If @Primary_Prod_Code is Not Null
  If @Alternate_Prod_Code is not Null
    Delete FROM #Output WHERE product <> @Alternate_Prod_Code and product <> @Primary_Prod_Code
  Else
    Delete FROM #Output WHERE product <> @Primary_Prod_Code
Else
 If @Alternate_Prod_Code is not Null
    Delete FROM #Output WHERE  product <> @Alternate_Prod_Code
If @ClientVersion = 4
  Begin
 	 SELECT @SqlStmt = 'SELECT Event_Id,Icon_Id,PU_Id,[' + @Col4 + '] = EventNum,[' + @Col5 + '] = EventStatus,[' + @Col6 + '] = Product,['
 	 SELECT @SqlStmt =  @SqlStmt + @Col7 + '] = Time,[' + @Col8 + ']= coalesce(Age,0)'
 	 SELECT @SqlStmt =  @SqlStmt + ',[' + @XTitle + '] = ' + 'DimX'
 	 SELECT @SqlStmt =  @SqlStmt + case When @YEnabled = 1 Then ',[' + @YTitle + '] = ' + 'DimY'   Else ' ' End
 	 SELECT @SqlStmt =  @SqlStmt + case When @ZEnabled = 1 Then ',[' + @ZTitle + '] = ' + 'DimZ'  Else ' ' End
 	 SELECT @SqlStmt =  @SqlStmt + case When @AEnabled = 1 Then ',[' + @ATitle + '] = ' + 'DimA'  Else ' ' End
 	 SELECT @SqlStmt =  @SqlStmt + ',[' + @Col13 + '] = ' + 'Location'
 	 SELECT @SqlStmt =  @SqlStmt + ' FROM #Output Order BY '
 	 SELECT @SqlStmt =  @SqlStmt + @SortOrder
  End
Else
  Begin
 	 SELECT @SqlStmt = 'SELECT Event_Id,Icon_Id,PU_Id,[Event] = EventNum,[Status] = EventStatus,Product,Time,Age = coalesce(Age,0)'
 	 SELECT @SqlStmt =  @SqlStmt + ',[' + @XTitle + '] = ' + 'Coalesce(Convert(nvarchar(25),DimX),''N/A'')'
 	 SELECT @SqlStmt =  @SqlStmt + case When @YEnabled = 1 Then ',[' + @YTitle + '] = ' + 'Coalesce(Convert(nvarchar(25),DimY),''N/A'')'   Else ' ' End
 	 SELECT @SqlStmt =  @SqlStmt + case When @ZEnabled = 1 Then ',[' + @ZTitle + '] = ' + 'Coalesce(Convert(nvarchar(25),DimZ),''N/A'')'  Else ' ' End
 	 SELECT @SqlStmt =  @SqlStmt + case When @AEnabled = 1 Then ',[' + @ATitle + '] = ' + 'Coalesce(Convert(nvarchar(25),DimA),''N/A'')'  Else ' ' End
 	 SELECT @SqlStmt =  @SqlStmt + ' FROM #Output Order by EventNum'
  End
SET Rowcount @MaxRows
Execute(@SqlStmt)
SET Rowcount 0
drop table #Output
