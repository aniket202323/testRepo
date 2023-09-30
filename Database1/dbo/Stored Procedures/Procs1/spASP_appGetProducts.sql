CREATE PROCEDURE dbo.spASP_appGetProducts
@ProductGroup int = Null, 
@Order int = 0,
@STime datetime = Null,
@ETime datetime = Null,
@Exclude_String varchar(7900) = Null,
@PU_Id int = Null, 
@Mask_String nvarchar(25) = Null,
@Mask_Key int = null,
@SelectedVariables nVarChar(1000) = Null,
@InTimeZone nvarchar(200)=NULL
As
Execute spRS_GetProducts
 	 @ProductGroup = @ProductGroup,
 	 @Order = @Order,
 	 @STime = @STime,
 	 @ETime = @ETime,
 	 @Exclude_String = @Exclude_String,
 	 @PU_Id = @PU_Id, 
 	 @Mask_String = @Mask_String,
 	 @Mask_Key = @Mask_Key,
 	 @SelectedVariables = @SelectedVariables,
 	 @InTimeZone = @InTimeZone
