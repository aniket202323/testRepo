--------------------------------------------------------------------------------------------------
-- Stored Procedure: spLocal_Util_SaveMasterBOMFormulation
--------------------------------------------------------------------------------------------------
-- Author				: Sasha Metlitski, Symasol
-- Date created			: 01-Nov-2019	
-- Version 				: Version <1.0>
-- SP Type				: UI
-- Caller				: Called by BOM Utility UI
-- Description			: This Stored Procedue Saves Master BOM Formulation
-- Editor tab spacing	: 4
-------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------
-- EDIT HISTORY:
--------------------------------------------------------------------------------------------------
-- ========		====	  		====					=====
-- 1.0			07-Nov-2019		A.Metlitski				Original

/*---------------------------------------------------------------------------------------------
Testing Code

declare @dd datetime
select @dd = getdate()
exec dbo.spLocal_Util_SaveMasterBOMFormulation Null 2807,79, '191101130005', 7310, 12, @dd,60, '1911011300', 100  --2659, ''--2879, ''
-----------------------------------------------------------------------------------------------*/


--------------------------------------------------------------------------------
CREATE PROCEDURE		[dbo].[spLocal_Util_SaveMasterBOMFormulation]
						@MasterBOMFormulationId		int output,
						@MasterBOMFamilyId			int,
						@MasterBOMId				int,
						@MasterBOMFormulationDesc	nvarchar(255)	= Null,
						@MasterBOMFormulationUOMId	int				= Null,
						@EffectiveDate				datetime		= Null,
						@Comment					nvarchar(255)	= NuLL,						
						@OriginGroupList			nvarchar(max)	= Null,
						@OriginGroupMaterialList	nvarchar(max)	= Null,
						@OriginGroupQtyList			nvarchar(max)	= Null,
						@OrigingGroupUOMList		nvarchar(max)	= Null,	
						@OrigingGroupScrapList		nvarchar(max)	= Null,	
						@OrigingGroupLocationList	nvarchar(max)	= Null,	
						@OriginGroupAltMaterialList	nvarchar(max)	= Null,
						@OriginGroupAlyQtyList		nvarchar(max)	= Null,
						@OrigingGroupAltUOMList		nvarchar(max)	= Null
					

					


--WITH ENCRYPTION
AS
SET NOCOUNT ON

if @MasterBOMFormulationId Is Null
select @MasterBOMFormulationId = -991

select @MasterBOMFormulationId

/*
DECLARE @B2MML nvarchar(max)
DECLARE	@SiteEquipmentId	nvarchar(255),
		@ProductionScheduleId	nvarchar(255),
		@ThisTime		datetime,
		@YYYY			nvarchar(4),
		@YY				nvarchar(2),
		@MM				nvarchar(2),
		@DD				nvarchar(2),
		@HH				nvarchar(2),
		@MI				nvarchar(2),
		@SS				nvarchar(2),
		@MS				nvarchar(3),
		@ProdDesc		nvarchar(255),
		@ProdCode		nvarchar(255),
		@ProductProductionRuleID	nvarchar(255),
		@EndTime		datetime,
		@SegmentRequirementId	nvarchar(255),
		@PathCode				nvarchar(255),
		@MaterialDefinitionId	nvarchar(255),
		@MaterialDefinitionDesc	nvarchar(255),
		@StandardQty			float,
		@MCRQty					float,
		@UOM					nvarchar(255),
		@MaterialReservationId	nvarchar(10),
		@MaterialReservationSequence	nvarchar(4),
		@ScrapPercent			float,
		@OriginGroup			nvarchar(255),
		@OriginGroupDesc		nvarchar(255),
		@MaterialSequenceNumber	nvarchar(6),
		@AltMaterial			nvarchar(18),
		@ii	int,
		@StorageZone	nvarchar(255)
		

select	@SiteEquipmentId = Null
select	@SiteEquipmentId = convert(nvarchar(255),peec.value)
--select peec.value
from	dbo.Property_Equipment_EquipmentClass peec
join	dbo.EquipmentClass ec on peec.Class = ec.EquipmentClassName
join	dbo.Equipment e on peec.EquipmentId = e.EquipmentId
where	peec.Name = 'PartnerProfile'

SELECT	@ProdCode = NULL,
		@ProdDesc = NULL	

SELECT	@ProdCode = p.Prod_Code,
		@ProdDesc = p.Prod_Desc	
FROM	dbo.PRODUCTS_BASE p
WHERE	p.Prod_Id = @ProdId

select @MaterialDefinitionId = @ProdCode
while len(@MaterialDefinitionId) < 12
begin
	select @MaterialDefinitionId = '0' + @MaterialDefinitionId 
end

select	@ProductProductionRuleID = NULL
select	@ProductProductionRuleID = bom.BOM_Desc
from	dbo.Bill_Of_Material bom
where	bom.BOM_Id = @BOMId


select	@EndTime = dateadd(MI, @duration, @StartTime)
select	@SegmentRequirementId = '1'

select	@PathCode = pex.Path_Code
from	Prdexec_Paths	pex
where	pex.Path_Id = @PathId



select	@ThisTime	=	getdate()
select	@YYYY		=	convert (varchar(255), datepart(YY, @ThisTime))
select	@MM			=	convert (varchar(255), datepart(MM, @ThisTime))
select	@DD			=	convert (varchar(255), datepart(DD, @ThisTime))
select	@HH			=	convert (varchar(255), datepart(HH, @ThisTime))
select	@MI			=	convert (varchar(255), datepart(MI, @ThisTime))
select	@SS			=	convert (varchar(255), datepart(SS, @ThisTime))
select	@MS			=	convert (varchar(255), datepart(MS, @ThisTime))

if len(@MM) < 2
begin
	select @MM = '0'+@MM
end

if len(@DD) < 2
begin
	select @DD = '0'+@DD
end

if len(@HH) < 2
begin
	select @HH = '0'+@HH
end

if len(@MI) < 2
begin
	select @MI = '0'+@MI
end

if len(@SS) < 2
begin
	select @SS = '0'+@SS
end

if len(@MS) <2
begin
	select @SS = '00'+@SS
end

if len(@MS) <3
begin
	select @SS = '0'+@SS
end


select @ProductionScheduleId = @YYYY + @MM + @DD + @HH + @MI + @SS + @MS
select @MaterialReservationId = @YYYY + @MM + @DD + @HH


select	@StandardQty = bomf.Standard_Quantity,
		@UOM = eu.Eng_Unit_Desc		
from	dbo.Bill_Of_Material_Formulation bomf with (nolock)
join	dbo.Engineering_Unit eu on bomf.Eng_Unit_Id = eu.Eng_Unit_Id
where	bomf.BOM_Formulation_Id = @MasterBOMFormulationId

select	@OriginGroup = Null
select	@OriginGroup = convert(nvarchar(255),pmdmc.Value)
from	dbo.Products_Base p 
join	dbo.Products_Aspect_MaterialDefinition pamd on p.Prod_Id = pamd.Prod_Id
join	dbo.MaterialDefinition md on pamd.Origin1MaterialDefinitionId = md.MaterialDefinitionId
join	dbo.Property_MaterialDefinition_MaterialClass pmdmc on md.MaterialDefinitionId = pmdmc.MaterialDefinitionId 
where	pmdmc.name = 'origin group' and pmdmc.Class = 'Base Material Linkage' and p.Prod_Id = @ProdId


if len(isNull(@OriginGroup,'')) > 0
begin
	select @OriginGroupDesc = Null
	select @OriginGroupDesc = tfv.value
	from dbo.Table_Fields_Values tfv 
	join	dbo.tables on tfv.TableId = tables.TableId
	join	dbo.Table_Fields tf on tfv.Table_Field_Id = tf.Table_Field_Id
	join		dbo.Subscription s on tfv.KeyId = s.Subscription_Id
	join	dbo.Subscription_Group sg on s.Subscription_Group_Id = sg.Subscription_Group_Id and sg.Subscription_Group_Desc = 'origin Groups'
	where	s.Subscription_Desc = @OriginGroup
	and	tf.Table_Field_Desc = 'OG - Description'
end



-- MPR Storage Zone
select @StorageZone  =Null
select @StorageZone = tfv.value
from	dbo.Table_Fields_Values tfv 
join	dbo.tables on tfv.TableId = tables.TableId
join	dbo.Table_Fields tf on tfv.Table_Field_Id = tf.Table_Field_Id
join	dbo.Prdexec_Paths pex on tfv.KeyId = pex.Path_Id
where	tf.Table_Field_Desc = 'PE_WF_ProductionStorageLocation'
 and	pex.Path_Id = @Pathid


SELECT @B2MML = '<?xml version="1.0"?><ProductionSchedule xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:Extended="http://www.wbf.org/xml/B2MML-V0401-AllExtensions" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns="http://www.wbf.org/xml/B2MML-V0401">'
SELECT @B2MML = @B2MML + '<ID>' + IsNull(@ProductionScheduleId,'') + '</ID>'
SELECT @B2MML = @B2MML + '<Location><EquipmentID>' + IsNull(@SiteEquipmentId,'') + '</EquipmentID>'+ '<EquipmentElementLevel>Site</EquipmentElementLevel><Location><EquipmentID>0</EquipmentID><EquipmentElementLevel>Area</EquipmentElementLevel></Location></Location><ProductionRequest>'
SELECT @B2MML = @B2MML +  '<ID>' + IsNull(@ProcessOrder,'') + '</ID>'
SELECT @B2MML = @B2MML +  '<Description>'+ IsNull(@ProdDesc,'') + '</Description>'
SELECT @B2MML = @B2MML +  '<ProductProductionRuleID>' + IsNull(@ProductProductionRuleID,'') + '</ProductProductionRuleID>'
SELECT @B2MML = @B2MML +  '<StartTime>' + convert(nvarchar(255),@StartTime,126) + '</StartTime>'
SELECT @B2MML = @B2MML +  '<EndTime>' + convert(nvarchar(255),@EndTime,126) + '</EndTime>'
SELECT @B2MML = @B2MML +  '<SegmentRequirement>'
SELECT @B2MML = @B2MML +  '<ID>'+ @SegmentRequirementId +'</ID>'
SELECT @B2MML = @B2MML +  '<EarliestStartTime>' + convert(nvarchar(255),@StartTime,126) + '</EarliestStartTime>'
SELECT @B2MML = @B2MML +  '<LatestEndTime>' + convert(nvarchar(255),@EndTime,126) + '</LatestEndTime>'
SELECT @B2MML = @B2MML +  '<EquipmentRequirement>'
SELECT @B2MML = @B2MML +  '<EquipmentID>' + IsNUll(@PathCode,'') + '</EquipmentID>'
SELECT @B2MML = @B2MML +  '</EquipmentRequirement>'
SELECT @B2MML = @B2MML +  '<MaterialProducedRequirement>'
SELECT @B2MML = @B2MML +  '<MaterialDefinitionID>' + IsNull(@MaterialDefinitionId,'') + '</MaterialDefinitionID>'
SELECT @B2MML = @B2MML +  '<MaterialLotID>' + IsNUll(@BatchNumber,'') + '</MaterialLotID>'
SELECT @B2MML = @B2MML +  '<Description>' + IsNull(@ProdDesc,'')  + '</Description>'
SELECT @B2MML = @B2MML +  '<Location>'
SELECT @B2MML = @B2MML +  '<EquipmentID>' + IsNull(@SiteEquipmentId,'') + '</EquipmentID>'
SELECT @B2MML = @B2MML +  '<EquipmentElementLevel>Site</EquipmentElementLevel>'
SELECT @B2MML = @B2MML +  '<Location>'
SELECT @B2MML = @B2MML +  '<EquipmentID>' + @StorageZone + '</EquipmentID>'
SELECT @B2MML = @B2MML +  '<EquipmentElementLevel>StorageZone</EquipmentElementLevel>'
SELECT @B2MML = @B2MML +  '</Location>'
SELECT @B2MML = @B2MML +  '</Location>'
SELECT @B2MML = @B2MML +  '<Quantity>'
SELECT @B2MML = @B2MML +  '<QuantityString>' + convert(varchar(255),convert(decimal(38,2),IsNUll(@Qty,0))) + '</QuantityString>'
SELECT @B2MML = @B2MML +  '<DataType>float</DataType>'
SELECT @B2MML = @B2MML +  '<UnitOfMeasure>' + IsNull(@uom,'') + '</UnitOfMeasure>'
SELECT @B2MML = @B2MML +  '</Quantity>'
SELECT @B2MML = @B2MML +  '<MaterialProducedRequirementProperty>'
SELECT @B2MML = @B2MML +  '<ID>Origin GroupID</ID>'
SELECT @B2MML = @B2MML +  '<Value>'
SELECT @B2MML = @B2MML +  '<ValueString>' + IsNull(@OriginGroup,'') + '</ValueString>'
SELECT @B2MML = @B2MML +  '<DataType>string</DataType>'
SELECT @B2MML = @B2MML +  '</Value>'
SELECT @B2MML = @B2MML +  '</MaterialProducedRequirementProperty>'
SELECT @B2MML = @B2MML +  '<MaterialProducedRequirementProperty>'
SELECT @B2MML = @B2MML +  '<ID>Origin Group</ID>'
SELECT @B2MML = @B2MML +	'<Value>'
SELECT @B2MML = @B2MML +  '<ValueString>' + IsNUll(@OriginGroupDesc,'') + '</ValueString>'
SELECT @B2MML = @B2MML +  '<DataType>string</DataType>'
SELECT @B2MML = @B2MML +  '</Value>'
SELECT @B2MML = @B2MML +  '</MaterialProducedRequirementProperty>'


SELECT @B2MML = @B2MML +  '</MaterialProducedRequirement>'

DECLARE @tBOMFormulationItems table(
		Id int identity			(1,1),
		BOMFormulationItemId	int,
		Alias					nvarchar(255),
		BOMFormulationOrder	int,
		Eng_Unit_Id				int,
		Location_Id				int,
		ProdId					int,
		PUId					int,
		Quantity				float,
		Scrap_Factor			float)

insert	@tBOMFormulationItems(
		BOMFormulationItemId,
		Alias,
		BOMFormulationOrder,
		Eng_Unit_Id,
		Location_Id,
		ProdId,
		PUId,
		Quantity,
		Scrap_Factor)
select	bomfi.BOM_Formulation_Item_Id,
		bomfi.Alias,
		bomfi.BOM_Formulation_Order,
		bomfi.Eng_Unit_Id,
		bomfi.Location_Id,
		bomfi.Prod_Id,
		bomfi.PU_Id,
		bomfi.Quantity,
		bomfi.Scrap_Factor
from	dbo.Bill_Of_Material_Formulation_Item bomfi
where	bomfi.BOM_Formulation_Id  = @MasterBOMFormulationId
order by bomfi.BOM_Formulation_Order




 select @ii = min(id) from @tBOMFormulationItems
 
 
 
 while @ii <= (select max(id) from @tBOMFormulationItems)
 begin
	
	SELECT	@B2MML = @B2MML +  '<MaterialConsumedRequirement>'
	
	select	@MaterialDefinitionId = Null,
			@MaterialDefinitionDesc = Null,
			@MCRQty = Null,
			@UOM = NULL
	
	
	
	select	@MaterialDefinitionId = p.Prod_Code,
			@MaterialDefinitionDesc = p.Prod_Desc,
			@MCRQty = IsNull(tbomfi.Quantity,0) * (@Qty/@StandardQty),
			@UOM = eu.Eng_Unit_Desc,
			@MaterialReservationSequence = convert(varchar(4),IsNUll(tbomfi.BOMFormulationOrder,0)),
			@MaterialSequenceNumber = convert(varchar(4),IsNUll(tbomfi.BOMFormulationOrder,0)),
			@ScrapPercent	= tbomfi.Scrap_Factor
	from	dbo.Products_Base p with (nolock) 
	join	@tBOMFormulationItems tbomfi on p.Prod_Id = tbomfi.ProdId
	join	dbo.Engineering_Unit eu on tbomfi.Eng_Unit_Id = eu.Eng_Unit_Id
	where	tbomfi.id = @ii


	select	@OriginGroup = Null
	select	@OriginGroup = convert(nvarchar(255),pmdmc.Value)
	from	@tBOMFormulationItems tbd
	join	dbo.Products_Base p on tbd.ProdId = p.Prod_Id
	join	dbo.Products_Aspect_MaterialDefinition pamd on p.Prod_Id = pamd.Prod_Id
	join	dbo.MaterialDefinition md on pamd.Origin1MaterialDefinitionId = md.MaterialDefinitionId
	join	dbo.Property_MaterialDefinition_MaterialClass pmdmc on md.MaterialDefinitionId = pmdmc.MaterialDefinitionId 
	where	pmdmc.name = 'origin group' and pmdmc.Class = 'Base Material Linkage'

	if len(isNull(@OriginGroup,'')) > 0
	begin
		select	@OriginGroupDesc = Null
		select	@OriginGroupDesc = tfv.value
		from	dbo.Table_Fields_Values tfv 
		join	dbo.tables on tfv.TableId = tables.TableId
		join	dbo.Table_Fields tf on tfv.Table_Field_Id = tf.Table_Field_Id
		join	dbo.Subscription s on tfv.KeyId = s.Subscription_Id
		join	dbo.Subscription_Group sg on s.Subscription_Group_Id = sg.Subscription_Group_Id and sg.Subscription_Group_Desc = 'origin Groups'
		where	s.Subscription_Desc = @OriginGroup
		and		tf.Table_Field_Desc = 'OG - Description'
end



	
	while len(@MaterialDefinitionId) < 18
	begin
		select @MaterialDefinitionId = '0' + @MaterialDefinitionId 
	end

	while len(@MaterialReservationSequence) < 4
	begin
		select @MaterialReservationSequence = '0' + @MaterialReservationSequence 
	end

	select @MaterialSequenceNumber = @MaterialSequenceNumber + '0'
	
	while len(@MaterialSequenceNumber) < 6
	begin
		select @MaterialSequenceNumber = '0' + @MaterialSequenceNumber 
	end
	
	/*
	select	@Qty = Null
	select	@qty = tbomfi.Quantity
	from	@tBOMFormulationItems tbomfi
	where	id = @ii
	*/
	select @StorageZone = Null 
	select @StorageZone =  x.Foreign_Key
	from	@tBOMFormulationItems tbomfi
join	dbo.Data_Source_XRef x on tbomfi.PUId = x.Actual_Id
join	dbo.Data_Source ds on x.DS_Id = ds.DS_Id
join	dbo.tables t	on x.Table_Id = t.TableId
where	tbomfi.id = @ii and
		ds.DS_Desc = 'Open Enterprise' and
		t.TableName = 'Prod_Units' 

		select @AltMaterial = Null
		select @AltMaterial  = p.Prod_Code
		from	dbo.Bill_Of_Material_Substitution boms
		join	@tBOMFormulationItems tbomfi on boms.BOM_Formulation_Item_Id = tbomfi.BOMFormulationItemId
		join	dbo.Products_base p on boms.Prod_Id = p.Prod_Id
		where	tbomfi.Id = @ii

		If len(IsNull(@AltMaterial,'')) > 0
		begin
			
				while len(@AltMaterial) < 18
				begin
					select @AltMaterial = '0' + @AltMaterial 
				end
		end
		
		--select @AltMaterial as alt
	SELECT @B2MML = @B2MML +  '<MaterialDefinitionID>' + IsNull(@MaterialDefinitionId,'') + '</MaterialDefinitionID>'
	SELECT @B2MML = @B2MML +  '<Description>' + IsNull(@MaterialDefinitionDesc,'') + '</Description>'
	SELECT @B2MML = @B2MML +	'<Location><EquipmentID>' + IsNull(@SiteEquipmentId,'') + '</EquipmentID>'+ '<EquipmentElementLevel>Site</EquipmentElementLevel>'
	SELECT @B2MML = @B2MML +	'<Location><EquipmentID>' + IsNull(@StorageZone,'') + '</EquipmentID>'+ '<EquipmentElementLevel>StorageZone</EquipmentElementLevel>'
	SELECT @B2MML = @B2MML +	'<Location><EquipmentID>LN01</EquipmentID><EquipmentElementLevel>WorkCenter</EquipmentElementLevel></Location>'
	SELECT @B2MML = @B2MML +	'</Location>'
	SELECT @B2MML = @B2MML +	'</Location>'
	SELECT @B2MML = @B2MML +	'<Quantity>'
	SELECT @B2MML = @B2MML +    '<QuantityString>' + convert(varchar(255),convert(decimal(38,2),IsNull(@MCRQty,0))) + '</QuantityString>'
	SELECT @B2MML = @B2MML +    '<DataType>float</DataType>'
	SELECT @B2MML = @B2MML +    '<UnitOfMeasure>' + @UOM + '</UnitOfMeasure>'
	SELECT @B2MML = @B2MML +	'</Quantity>'
	
	SELECT @B2MML = @B2MML +	'<MaterialConsumedRequirementProperty>'
	SELECT @B2MML = @B2MML +	'<ID>MaterialReservationID</ID>' 
	SELECT @B2MML = @B2MML +	'<Description/>'
	SELECT @B2MML = @B2MML +	'<Value>'
	SELECT @B2MML = @B2MML +	'<ValueString>'+ IsNUll(@MaterialReservationId,'')  + '</ValueString>'
	SELECT @B2MML = @B2MML +	'<DataType>string</DataType>'
	SELECT @B2MML = @B2MML +	'</Value>'
	SELECT @B2MML = @B2MML +	'</MaterialConsumedRequirementProperty>'

	SELECT @B2MML = @B2MML +	'<MaterialConsumedRequirementProperty>'
	SELECT @B2MML = @B2MML +	'<ID>MaterialReservationSequence</ID>'
	SELECT @B2MML = @B2MML +	'<Value>'
	SELECT @B2MML = @B2MML +	'<ValueString>'+ IsNull(@MaterialReservationSequence,'')  + '</ValueString>'
	SELECT @B2MML = @B2MML +	'</Value>'
	SELECT @B2MML = @B2MML +	'</MaterialConsumedRequirementProperty>'

	SELECT @B2MML = @B2MML +	'<MaterialConsumedRequirementProperty>'
	SELECT @B2MML = @B2MML +	'<ID>ScrapPercent</ID>'
	SELECT @B2MML = @B2MML +	'<Value>'
	SELECT @B2MML = @B2MML +	'<ValueString>'+ convert(varchar(255),IsNull(@ScrapPercent,0))  + '</ValueString>'
	SELECT @B2MML = @B2MML +	'</Value>'
	SELECT @B2MML = @B2MML +	'</MaterialConsumedRequirementProperty>'

	SELECT @B2MML = @B2MML +	'<MaterialConsumedRequirementProperty>'
	SELECT @B2MML = @B2MML +	'<ID>MaterialOriginGroup</ID>'
	SELECT @B2MML = @B2MML +	'<Value>'
	SELECT @B2MML = @B2MML +	'<ValueString>'+ IsNull(@OriginGroup,'')  + '</ValueString>'
	SELECT @B2MML = @B2MML +	'</Value>'
	SELECT @B2MML = @B2MML +	'</MaterialConsumedRequirementProperty>'

	SELECT @B2MML = @B2MML +	'<MaterialConsumedRequirementProperty>'
	SELECT @B2MML = @B2MML +	'<ID>MaterialOriginGroupDesc</ID>'	
	SELECT @B2MML = @B2MML +	'<Description/>'
	SELECT @B2MML = @B2MML +	'<Value>'
	SELECT @B2MML = @B2MML +	'<ValueString>'+ iSnULL(@OriginGroupDesc,'') + '</ValueString>'
	SELECT @B2MML = @B2MML +	'<DataType>string</DataType>'
	SELECT @B2MML = @B2MML +	'</Value>'
	SELECT @B2MML = @B2MML +	'</MaterialConsumedRequirementProperty>'

	SELECT @B2MML = @B2MML +	'<MaterialConsumedRequirementProperty>'
	SELECT @B2MML = @B2MML +	'<ID>MaterialSequenceNumber</ID>'	
	SELECT @B2MML = @B2MML +	'<Description/>'
	SELECT @B2MML = @B2MML +	'<Value>'
	SELECT @B2MML = @B2MML +	'<ValueString>'+ IsNull(@MaterialSequenceNumber,'')  + '</ValueString>'
	SELECT @B2MML = @B2MML +	'<DataType>string</DataType>'
	SELECT @B2MML = @B2MML +	'</Value>'
	SELECT @B2MML = @B2MML +	'</MaterialConsumedRequirementProperty>'
	
	if @AltMaterial is Not Null
	begin
		SELECT @B2MML = @B2MML +	'<MaterialConsumedRequirementProperty>'
		SELECT @B2MML = @B2MML +	'<ID>Alternate</ID>'	
		SELECT @B2MML = @B2MML +	'<Description/>'
		SELECT @B2MML = @B2MML +	'<Value>'
		SELECT @B2MML = @B2MML +	'<ValueString>' + @AltMaterial + '</ValueString>'
		SELECT @B2MML = @B2MML +	'<DataType>string</DataType>'
		SELECT @B2MML = @B2MML +	'</Value>'
		SELECT @B2MML = @B2MML +	'</MaterialConsumedRequirementProperty>'
	end
	
	SELECT @B2MML = @B2MML +  '</MaterialConsumedRequirement>'
	--select @MCRQty as MCRQty
	select @ii = @ii + 1
	--select @ii
 end
 SELECT @B2MML = @B2MML + '</SegmentRequirement>'
 SELECT @B2MML = @B2MML + '</ProductionRequest>'
 SELECT @B2MML = @B2MML + '</ProductionSchedule>'

 select @B2MML

 /*
 insert dbo.Local_tblINTIntegrationMessages (
		Site,
		SystemSource,
		SystemTarget,
		MessageType,
		Message,
		MainData,
		InsertedDate)

select	@@servername,	
		'SAP',
		'MES',
		'WorkOrder',
		@B2MML,
		@ProcessOrder,
		getdate()
*/
*/




RETURN


SET NOcount OFF
