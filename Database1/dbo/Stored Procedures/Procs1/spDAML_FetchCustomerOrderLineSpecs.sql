Create Procedure dbo.spDAML_FetchCustomerOrderLineSpecs
    @OrderLineSpecId 	 INT = NULL,
    @CustomerName 	 VARCHAR(100) = NULL,
    @PlantOrder 	  	 VARCHAR(50) = NULL,
 	 @LineNumber 	  	 INT = NULL,
 	 @SpecName 	  	 VARCHAR(100) = NULL
AS
-- Local variables
DECLARE 	 
    @SecurityClause VARCHAR(100),
    @IdClause 	  	 VARCHAR(50),
    @OptionsClause  VARCHAR(1000),
    @TimeClause 	  	 VARCHAR(500),
 	 @WhereClause 	 VARCHAR(2000),
    @SelectClause   VARCHAR(4000),
    @OrderClause 	 VARCHAR(500)
-- Customer order lines specs have no special security
SET @SecurityClause = ' WHERE 1=1 '
-- One and only one of the following id values is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@OrderLineSpecId<>0 AND @OrderLineSpecId IS NOT NULL) THEN ' AND ols.Order_Spec_Id = ' + CONVERT(VARCHAR(10), @OrderLineSpecId) + ' '
   ELSE ''
END
-- All of the following are optional and some or none can apply
-- The query will use LIKE only if a wildcard character si specified
SET @OptionsClause = ''
IF (@CustomerName<>'' AND @CustomerName IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @CustomerName)=0 AND CHARINDEX('_', @CustomerName)=0 )
     SET @OptionsClause = @OptionsClause + ' AND c.Customer_Name = ''' + CONVERT(VARCHAR(100),@CustomerName) + ''' '
   ELSE
      SET @OptionsClause = @OptionsClause + ' AND c.Customer_Name LIKE ''' + CONVERT(VARCHAR(100),@CustomerName) + ''' '
END
IF (@PlantOrder<>'' AND @PlantOrder IS NOT NULL) BEGIN
   IF ( CHARINDEX('%',@PlantOrder)=0 AND CHARINDEX('_', @PlantOrder)=0 )
     SET @OptionsClause = @OptionsClause + ' AND o.Plant_Order_Number = ''' + CONVERT(VARCHAR(50),@PlantOrder) + ''' '
   ELSE
      SET @OptionsClause = @OptionsClause + ' AND o.Plant_Order_Number LIKE ''' + CONVERT(VARCHAR(50),@PlantOrder) + ''' '
END
IF (@LineNumber<>0 AND @LineNumber IS NOT NULL) BEGIN
     SET @OptionsClause = @OptionsClause + ' AND oli.Line_Item_Number = ' + CONVERT(VARCHAR(10),@LineNumber) + ' '
END 
IF (@SpecName<>'' AND @SpecName IS NOT NULL) BEGIN
   IF ( CHARINDEX('%',@SpecName)=0 AND CHARINDEX('_', @SpecName)=0 )
     SET @OptionsClause = @OptionsClause + ' AND ols.Spec_Desc = ''' + CONVERT(VARCHAR(100),@SpecName) + ''' '
   ELSE
      SET @OptionsClause = @OptionsClause + ' AND ols.Spec_Desc LIKE ''' + CONVERT(VARCHAR(100),@SpecName) + ''' '
END
-- Customer order line specs have no time clause
SET @TimeClause = ''
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
SET @SelectClause =
'SELECT 	  	 CustomerOrderLineSpecId 	 = ols.Order_Spec_Id,
 	  	  	 CustomerId 	  	  	 = IsNull(o.Customer_Id,0),
 	  	  	 CustomerName 	  	 = IsNull(c.Customer_Name,''''),
 	  	  	 PlantOrderNumber 	 = IsNull(o.Plant_Order_Number,''''),
 	  	  	 LineItemNumber 	  	 = IsNull(oli.Line_Item_Number,0),
 	  	  	 SpecName 	  	  	 = ols.Spec_Desc,
 	  	  	 DataTypeId 	  	  	 = ols.Data_Type_Id,
 	  	  	 DataType 	  	  	 = IsNull(dt.Data_Type_Desc,''''),
 	  	  	 SpecPrecision 	  	 = IsNull(ols.Spec_Precision, 0),
 	  	  	 LowerLimit 	  	  	 = CASE
 	  	  	  	  	  	  	  	  	 WHEN 	 ISNUMERIC(ols.L_Limit) = 1 	 THEN 	 LTRIM(STR(ols.L_Limit, 50, IsNull(ols.Spec_Precision, 0)))
 	  	  	  	  	  	  	  	  	 ELSE 	 IsNull(ols.L_Limit,'''')
 	  	  	  	  	  	  	  	   END,
 	  	  	 Target 	  	  	  	 = CASE
 	  	  	  	  	  	  	  	  	 WHEN 	 ISNUMERIC(ols.Target) = 1 	 THEN 	 LTRIM(STR(ols.Target, 50, IsNull(ols.Spec_Precision, 0)))
 	  	  	  	  	  	  	  	  	 ELSE 	 IsNull(ols.Target,'''')
 	  	  	  	  	  	  	  	   END,
 	  	  	 UpperLimit 	  	  	 = CASE
 	  	  	  	  	  	  	  	  	 WHEN 	 ISNUMERIC(ols.U_Limit) = 1 	 THEN 	 LTRIM(STR(ols.U_Limit, 50, IsNull(ols.Spec_Precision, 0)))
 	  	  	  	  	  	  	  	  	 ELSE 	 IsNull(ols.U_Limit,'''')
 	  	  	  	  	  	  	  	   END,
 	  	  	 IsActive 	  	  	 = ols.Is_Active,
 	  	  	 CustomerOrderId 	  	 = o.Order_Id,
 	  	  	 CustomerOrderLineId 	 = oli.Order_Line_Id
 	 FROM 	  	  	 Customer_Order_Line_Specs ols
 	 INNER 	 JOIN 	 Data_Type dt 	  	  	  	  	  	  	 ON ols.Data_Type_Id = dt.Data_Type_Id
 	 INNER 	 JOIN 	 Customer_Order_Line_Items oli 	  	  	 ON 	 oli.Order_Line_Id = ols.Order_Line_Id
 	 INNER 	 JOIN 	 Customer_Orders o 	  	  	  	  	  	 ON 	 o.Order_Id = oli.Order_Id
 	 INNER 	 JOIN 	 Customer c 	  	  	  	  	  	  	  	 ON 	 c.Customer_Id = o.Customer_Id'
-- Order clause
SET @OrderClause = ' ORDER BY c.Customer_Name, o.Plant_Order_Number, oli.Line_Item_Number, ols.Spec_Desc'
--SELECT sc = @SelectClause, wc = @WhereClause, oc = @OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
