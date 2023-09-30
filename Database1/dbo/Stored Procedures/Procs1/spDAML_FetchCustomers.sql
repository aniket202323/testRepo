Create Procedure dbo.spDAML_FetchCustomers
    @CustId 	  	 INT = NULL,
    @CustName 	 VARCHAR(100) = NULL,
 	 @CustCode 	 VARCHAR(50) = NULL
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
-- Customers have no special security
SET @SecurityClause = ' WHERE 1=1 '
-- One and only one of the following id values is required
-- They are ordered from most narrow to least narrow
SELECT @IdClause = 
CASE WHEN (@CustId<>0 AND @CustId IS NOT NULL) THEN ' AND c.Customer_Id = ' + CONVERT(VARCHAR(10), @CustId) + ' '
   ELSE ''
END
-- All of the following are optional and some or none can apply
-- These can have a mask, but LIKE is only used if there is a mask applied
SET @OptionsClause = ''
IF (@CustName<>'' AND @CustName IS NOT NULL) BEGIN
   IF ( CHARINDEX('%', @CustName)=0 AND CHARINDEX('_', @CustName)=0 )
     SET @OptionsClause = @OptionsClause + ' AND c.Customer_Name = ''' + CONVERT(VARCHAR(100),@CustName) + ''' '
   ELSE
      SET @OptionsClause = @OptionsClause + ' AND c.Customer_Name LIKE ''' + CONVERT(VARCHAR(100),@CustName) + ''' '
END
IF (@CustCode<>'' AND @CustCode IS NOT NULL) BEGIN
   IF ( CHARINDEX('%',@CustCode)=0 AND CHARINDEX('_', @CustCode)=0 )
     SET @OptionsClause = @OptionsClause + ' AND c.Customer_Code = ''' + CONVERT(VARCHAR(50),@CustCode) + ''' '
   ELSE
      SET @OptionsClause = @OptionsClause + ' AND c.Customer_Code LIKE ''' + CONVERT(VARCHAR(50),@CustCode) + ''' '
END  
-- Customers have no time clause
SET @TimeClause = ''
-- The where clause consists of the security, the id, the options and the time
SET @WhereClause = @SecurityClause + @IdClause + @OptionsClause + @TimeClause
-- Set select clause
--   All NULL strings are converted to empty string
--   All NULL numerics are converted to 0
SET @SelectClause =
'SELECT 	  	 CustomerId 	  	  	 = c.Customer_Id,
 	  	  	 CustomerCode 	  	 = IsNull(c.Customer_Code,''''),
 	  	  	 CustomerName 	  	 = IsNull(c.Customer_Name,''''),
 	  	  	 ConsigneeCode 	  	 = IsNull(c.Consignee_Code,''''),
 	  	  	 ConsigneeName 	  	 = IsNull(c.Consignee_Name,''''),
 	  	  	 CustomerTypeId 	  	 = c.Customer_Type,
 	  	  	 CustomerType 	  	 = IsNull(ct.Customer_Type_Desc,''''),
 	  	  	 IsActive  	  	  	 = c.Is_Active,
 	  	  	 ContactName 	  	  	 = IsNull(c.Contact_Name,''''),
 	  	  	 ContactPhone 	  	 = IsNull(c.Contact_Phone,''''),
 	  	  	 Address1 	  	  	 = IsNull(c.Address_1,''''),
 	  	  	 Address2 	  	  	 = IsNull(c.Address_2,''''),
 	  	  	 Address3 	  	  	 = IsNull(c.Address_3,''''),
 	  	  	 Address4 	  	  	 = IsNull(c.Address_4,''''),
 	  	  	 City 	  	  	  	 = IsNull(c.City,''''),
 	  	  	 County 	  	  	  	 = IsNull(c.County,''''),
 	  	  	 State 	  	  	  	 = IsNull(c.State,''''),
 	  	  	 Country 	  	  	  	 = IsNull(c.Country,''''),
 	  	  	 Zip 	  	  	  	  	 = IsNull(c.ZIP,''''),
 	  	  	 CustomerGeneral1 	 = IsNull(c.Customer_General_1,''''),
 	  	  	 CustomerGeneral2 	 = IsNull(c.Customer_General_2,''''),
 	  	  	 CustomerGeneral3 	 = IsNull(c.Customer_General_3,''''),
 	  	  	 CustomerGeneral4 	 = IsNull(c.Customer_General_4,''''),
 	  	  	 CustomerGeneral5 	 = IsNull(c.Customer_General_5,''''),
 	  	  	 ExtendedInfo 	  	 = IsNull(c.Extended_Info,'''')
 	 FROM 	 Customer c
 	 INNER JOIN 	 Customer_Types ct 	 ON 	 ct.Customer_Type_Id = c.Customer_Type '
-- order clause
SET @OrderClause = ' ORDER BY c.Customer_Name '
--SELECT sc = @SelectClause, wc = @WhereClause, oc = @OrderClause -- For debugging
EXECUTE (@SelectClause + @WhereClause + @OrderClause)
