
CREATE PROCEDURE [dbo].[spPS_BOMSaveFormulationItem]
    @BOM_Formulation_Id     INT,
    @ProductId              BIGINT,
    @Alias                  NVARCHAR(50)  = NULL,
    @BOM_Substitution_Order INT           = NULL,
    @Conversion_Factor      FLOAT         = NULL,
    @ScrapFactor            FLOAT         = NULL,
    @Quantity               FLOAT         = NULL,
    @Quantity_Precision     FLOAT         = NULL,
    @LowerTolerance         FLOAT         = NULL,
    @UpperTolerance         FLOAT         = NULL,
    @Eng_Unit_Id            BIGINT        = NULL,
    @PU_Id                  BIGINT        = NULL,
    @LTolerance_Precision   INT           = NULL,
    @UTolerance_Precision   INT           = NULL,
    @Location_Id            INT           = NULL,
    @Use_Event_Components   BIT           = NULL,
    @Substitution_ProductId INT,
    @Substitution_EngUnitId INT,
    @Substitution_Id        INT,
    @Item_Id                INT,
    @UserId                 INT,
    @paramType              NVARCHAR(200)
AS

/*---------------------------------------------------------------------------------------------------------------------
    This SP creates/updates BOM Formulation Item records
  
    Date         Ver/Build   Author               Story/Defect       Remarks
    16-Jun-2020  001         Sireesha                                Initial Development
    16-Aug-2020  002         Sireesha                                modifications for bom item creation and fetch list
    28-Jul-2020  003         Venky(503110410)     DEFECT             Added update logic,corrected format and documentation comments
    12-Aug-2020  004         Dan Stephens                            Fix for item sequence/order column incrementing over whole table.
                                                                        Now increments per BOM Formulation.
    25-Aug-2020  005         Dan Stephens         DE140399           Renamed SP from "dbo.spPS_CreateBOMFormulationItems" to "dbo.spPS_BOMSaveFormulationItem"
                                                                        Refactored CREATE/UPDATE to use existing base SP ("dbo.spEM_BOMSaveFormulationItem") to do the actual work.
    27-Aug-2020  006         Dan Stephens         DE140399           Added DELETE functionality
    17-Sep-2020  007         Dan Stephens         DE143524           Added Error output to DELETE, when Item_Id does not exist or is not attached to the incoming Bom_Formulation_Id
    07-Oct-2020  008         Dan Stephens         DE145008           Added error checking on a NULL product code to stop Item being deleted in UPDATE.
    07-Oct-2020  009         Dan Stephens         DE140288           Added/updated validation on BOM Formulation Id / BOM Formulation Item Id.
                                                                     Added Error Code/Messages Variables for easier tracking and re-use.
                                                                     Added validation on Engineering Unit Id in CREATE and UPDATE
    14-Oct-2020  010         Dan Stephens         DE140288           Added validation on PU_Id (Storage Unit)
    06-Nov-2020  011         Dan Stephens         DE146768           Fixed SIZE of @Alias parameter to match the core SP that this SP is a wrapper for (spEM_BOMSaveFormulationItem)

---------------------------------------------------------------------------------------------------------------------
    PARAMETERS:
        - 

    Return Codes:
        returns  Bill_Of_Material_Formulation_Item data based on Bom_formulation_id if successfully inserted/updated record

    NOTES:
        - Historic details of modifications before ver 004 mainly taken from Git commit details.
        - The base SP (dbo.spEM_BOMSaveFormulationItem) is expecting "TEXT" datatype for the comment.
          According to Microsoft, "TEXT" will be removed in "future" versions of SQL Server, so used "NVARCHAR(MAX)" instead.
          Also, as we are not using comments, have defaulted to an empty string.
        - We need to convert the incoming productId into a product_code, as the base SP requires the code not the Id
        - Previous version of SP gave a NULL value into "Lot_Desc". this is simulated in the base SP call
        - Got rid of the "= NULL" designator of "@ProductId", so that a ProductID is mandatory.
        - Substitution code commented, as it is also commented in the "product-service" java code.
        - Kept the distinct running of the base SP within the if blocks incase we need to bring SUBSTITUTION back.)
        - The base SP requires a UserID to be passed in to perform updates. Added this in.

    QUESTIONS:
        - Do we need to add our own error handling into this to push up to the "product-service"? Yes, see ver 007
        - Transaction handling required?
        - Do we actually need to output the entire item list for a BOM Formulation each time we run this SP for a valid transaction?

    TODO:
        - 
    
---------------------------------------------------------------------------------------------------------------------*/

SET NOCOUNT ON;

/* DECLARATIONS */
DECLARE @tempItemId      INT           = NULL,
        @tempComment     NVARCHAR(MAX) = '',
        @tempProductCode NVARCHAR(25)  = NULL,
        @tempLotDesc     NVARCHAR(50)  = NULL,
        @PARAMCREATE     NVARCHAR(10)  = 'CREATE',
        @PARAMUPDATE     NVARCHAR(10)  = 'UPDATE',
        @PARAMDELETE     NVARCHAR(10)  = 'DELETE',
        @PARAMSUBST      NVARCHAR(12)  = 'SUBSTITUTION';


/* ERROR MESSAGES */
DECLARE @PRODUCT_ID_NOT_EXIST_MSG          NVARCHAR(50) = 'Product Id does not exist',
        @PRODUCT_ID_NOT_EXIST_CODE         NVARCHAR(50) = 'EPS1016',
        @FORMULATION_ID_NOT_EXIST_MSG      NVARCHAR(50) = 'BOM Formulation Id does not exist',
        @FORMULATION_ID_NOT_EXIST_CODE     NVARCHAR(50) = 'EPS2101',
        @ITEM_ID_NOT_EXIST_MSG             NVARCHAR(50) = 'BOM Formulation Item Id does not exist',
        @ITEM_ID_NOT_EXIST_CODE            NVARCHAR(50) = 'EPS2102',
        @ENG_UNIT_ID_NOT_EXIST_MSG         NVARCHAR(50) = 'Unit of Measure Id does not exist',
        @ENG_UNIT_ID_NOT_EXIST_CODE        NVARCHAR(50) = 'EPS2107',
        @STORAGE_UNIT_ID_NOT_EXIST_MSG     NVARCHAR(50) = 'Storage Unit Id does not exist',
        @STORAGE_UNIT_ID_NOT_EXIST_CODE    NVARCHAR(50) = 'EPS2118';



-- VALIDATION before any CREATE/UPDATE/DELETE
-- make sure that the incoming BOM formulation Id exists
IF NOT EXISTS (SELECT 1 FROM dbo.Bill_Of_Material_Formulation bomf WHERE bomf.BOM_Formulation_Id = @BOM_Formulation_Id)
    BEGIN
        SELECT @FORMULATION_ID_NOT_EXIST_MSG  AS Error, @FORMULATION_ID_NOT_EXIST_CODE AS Code;
        RETURN;
    END;


/* Get ready */

-- convert the incoming @ProductId into a product_code for the base SP, as it requires a code not an id
SELECT @tempProductCode = prod.Prod_Code FROM dbo.Products prod WHERE prod.Prod_Id = @ProductId;



/* CREATE the BOM Formulation Item */
IF (@ParamType = @PARAMCREATE)
    BEGIN

        -- VALIDATION pre create
        -- make sure that the incoming Product exists
        IF (@tempProductCode IS NULL)
            BEGIN
                SELECT @PRODUCT_ID_NOT_EXIST_MSG  AS Error, @PRODUCT_ID_NOT_EXIST_CODE AS Code;
                RETURN;
            END;
        -- make sure that the incoming Eng Unit Id exists
        IF NOT EXISTS (SELECT 1 FROM dbo.Engineering_Unit engunit WHERE engunit.Eng_Unit_Id = @Eng_Unit_Id)
            BEGIN
                SELECT @ENG_UNIT_ID_NOT_EXIST_MSG  AS Error, @ENG_UNIT_ID_NOT_EXIST_CODE AS Code;
                RETURN;
            END;
        -- make sure that if not null, that the incoming PU_Id (Storage Unit) exists
        IF (@PU_Id IS NOT NULL) AND (NOT EXISTS (SELECT 1 FROM dbo.Prod_Units_Base pub WHERE pub.PU_Id = @PU_Id))
            BEGIN
                SELECT @STORAGE_UNIT_ID_NOT_EXIST_MSG  AS Error, @STORAGE_UNIT_ID_NOT_EXIST_CODE AS Code;
                RETURN;
            END;


        -- Get the Item Id ready for a create
        SET @tempItemId = NULL;

        -- Run the SP
        EXECUTE spEM_BOMSaveFormulationItem @User           = @UserId,
                                            @Alias          = @Alias,
                                            @UseComponents  = @Use_Event_Components,
                                            @Scrap          = @ScrapFactor,
                                            @qty            = @Quantity,
                                            @qtyprec        = @Quantity_Precision,
                                            @lowert         = @LowerTolerance,
                                            @uppert         = @UpperTolerance,
                                            @ltprec         = @LTolerance_Precision,
                                            @utprec         = @UTolerance_Precision,
                                            @Comment        = @tempComment,
                                            @eu             = @Eng_Unit_Id,
                                            @Unit           = @PU_Id,
                                            @Location       = @Location_Id,
                                            @Formulation    = @BOM_Formulation_Id,
                                            @Lot            = @tempLotDesc,
                                            @Product        = @tempProductCode,
                                            @Id             = @tempItemId OUTPUT;

    END;



/* UPDATE an existing BOM Formulation Item */
ELSE IF (@ParamType = @PARAMUPDATE)
    BEGIN

        -- VALIDATION pre update
        -- make sure that the incoming Product exists
        IF (@tempProductCode IS NULL)
            BEGIN
                SELECT @PRODUCT_ID_NOT_EXIST_MSG  AS Error, @PRODUCT_ID_NOT_EXIST_CODE AS Code;
                RETURN;
            END;
        -- make sure that the incoming BOM formulation Item Id exists, and is attached to the incoming BOM Formulation Id
        IF NOT EXISTS (SELECT 1 FROM dbo.Bill_Of_Material_Formulation_Item bomi
                        WHERE bomi.BOM_Formulation_Id = @BOM_Formulation_Id AND bomi.BOM_Formulation_Item_Id = @Item_Id)
            BEGIN
                SELECT @ITEM_ID_NOT_EXIST_MSG  AS Error, @ITEM_ID_NOT_EXIST_CODE AS Code;
                RETURN;
            END;
        -- make sure that the incoming Eng Unit Id exists
        IF NOT EXISTS (SELECT 1 FROM dbo.Engineering_Unit engunit WHERE engunit.Eng_Unit_Id = @Eng_Unit_Id)
            BEGIN
                SELECT @ENG_UNIT_ID_NOT_EXIST_MSG  AS Error, @ENG_UNIT_ID_NOT_EXIST_CODE AS Code;
                RETURN;
            END;
        -- make sure that if not null, that the incoming PU_Id (Storage Unit) exists
        IF (@PU_Id IS NOT NULL) AND (NOT EXISTS (SELECT 1 FROM dbo.Prod_Units_Base pub WHERE pub.PU_Id = @PU_Id))
            BEGIN
                SELECT @STORAGE_UNIT_ID_NOT_EXIST_MSG  AS Error, @STORAGE_UNIT_ID_NOT_EXIST_CODE AS Code;
                RETURN;
            END;


        -- Get the Item Id ready for an update
        SET @tempItemId = @Item_Id;

        -- Run the SP. The base SP already handles NULL values on certain columns, so we can pass the values through
        EXECUTE spEM_BOMSaveFormulationItem @User           = @UserId,
                                            @Alias          = @Alias,
                                            @UseComponents  = @Use_Event_Components,
                                            @Scrap          = @ScrapFactor,
                                            @qty            = @Quantity,
                                            @qtyprec        = @Quantity_Precision,
                                            @lowert         = @LowerTolerance,
                                            @uppert         = @UpperTolerance,
                                            @ltprec         = @LTolerance_Precision,
                                            @utprec         = @UTolerance_Precision,
                                            @Comment        = @tempComment,
                                            @eu             = @Eng_Unit_Id,
                                            @Unit           = @PU_Id,
                                            @Location       = @Location_Id,
                                            @Formulation    = @BOM_Formulation_Id,
                                            @Lot            = @tempLotDesc,
                                            @Product        = @tempProductCode,
                                            @Id             = @tempItemId OUTPUT;

    END;



/* DELETE an existing BOM Formulation Item */
ELSE IF (@ParamType = @PARAMDELETE)
    BEGIN
        -- VALIDATION pre delete
        -- make sure that the incoming BOM formulation Item Id exists, and is attached to the incoming BOM Formulation Id
        IF NOT EXISTS (SELECT 1 FROM dbo.Bill_Of_Material_Formulation_Item bomi
                        WHERE bomi.BOM_Formulation_Id = @BOM_Formulation_Id AND bomi.BOM_Formulation_Item_Id = @Item_Id)
            BEGIN
                SELECT @ITEM_ID_NOT_EXIST_MSG  AS Error, @ITEM_ID_NOT_EXIST_CODE AS Code;
                RETURN;
            END;

        -- Get the Item Id ready for a delete
        SET @tempItemId = @Item_Id;

        -- Run the SP. For a delete, the base SP only requires an Item Id
        EXECUTE spEM_BOMSaveFormulationItem @User           = NULL,
                                            @Alias          = NULL,
                                            @UseComponents  = NULL,
                                            @Scrap          = NULL,
                                            @qty            = NULL,
                                            @qtyprec        = NULL,
                                            @lowert         = NULL,
                                            @uppert         = NULL,
                                            @ltprec         = NULL,
                                            @utprec         = NULL,
                                            @Comment        = NULL,
                                            @eu             = NULL,
                                            @Unit           = NULL,
                                            @Location       = NULL,
                                            @Formulation    = NULL,
                                            @Lot            = NULL,
                                            @Product        = NULL,
                                            @Id             = @tempItemId OUTPUT;

    END;


/* We didn't get a valid partamType, so do nothing */
ELSE
    BEGIN
        -- exit back out to the caller.
        RETURN;
    END;




/* Old
IF (@paramType = 'SUBSTITUTION')
BEGIN
	INSERT INTO [dbo].[Bill_Of_Material_Substitution] (
		BOM_Formulation_Item_Id
		,BOM_Substitution_Order
		,Conversion_Factor
		,Eng_Unit_Id
		,Prod_Id
		)
	VALUES (
		@Insert_Id
		,@BOM_Substitution_Order
		,@Conversion_Factor
		,@Substitution_EngUnitId
		,@Substitution_ProductId
		);
END;
*/

/* Output result */
BEGIN
    SELECT p.prod_id
          ,bomfi.BOM_Formulation_Item_Id
          ,bomfi.Quantity
          ,bomfi.Quantity_Precision
          ,unit.eng_Unit_Id
          ,bomfi.Lower_Tolerance
          ,bomfi.Upper_Tolerance
          ,bomfi.UTolerance_Precision
          ,bomfi.LTolerance_Precision
          ,bomfi.PU_ID
          ,bomfi.BOM_Formulation_Order
          ,bomfi.Alias
          ,bomfi.Scrap_Factor
          ,bomfi.Use_Event_Components
      FROM dbo.Bill_Of_Material_Formulation_Item bomfi
           JOIN dbo.Engineering_unit unit ON bomfi.eng_Unit_Id = unit.eng_Unit_Id
           JOIN dbo.Products p ON bomfi.Prod_Id = p.Prod_Id
     WHERE bomfi.BOM_Formulation_Item_Id = @tempItemId;
END;

