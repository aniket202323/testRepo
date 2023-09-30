CREATE TABLE [dbo].[OEEAggregationSliceTypes] (
    [Slice_Type_Id] INT           IDENTITY (1, 1) NOT NULL,
    [Slice_Desc]    VARCHAR (100) NOT NULL,
    CONSTRAINT [OEEAggregationSliceTypes_PK_SliceTypeId] PRIMARY KEY CLUSTERED ([Slice_Type_Id] ASC),
    CONSTRAINT [OEEAggregation_UC_SliceDesc] UNIQUE NONCLUSTERED ([Slice_Desc] ASC)
);

