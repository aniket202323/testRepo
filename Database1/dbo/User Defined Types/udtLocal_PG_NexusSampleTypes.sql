CREATE TYPE [dbo].[udtLocal_PG_NexusSampleTypes] AS TABLE (
    [ID]             INT          NOT NULL,
    [SampleType]     VARCHAR (50) NOT NULL,
    [SampleQuantity] INT          NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC));

