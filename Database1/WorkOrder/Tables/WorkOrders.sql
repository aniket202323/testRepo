CREATE TABLE [WorkOrder].[WorkOrders] (
    [CreatedOn]                            DATETIMEOFFSET (7) NOT NULL,
    [CreatedBy]                            NVARCHAR (MAX)     NOT NULL,
    [LastModifiedOn]                       DATETIMEOFFSET (7) NOT NULL,
    [LastModifiedBy]                       NVARCHAR (MAX)     NOT NULL,
    [ConcurrencyToken]                     ROWVERSION         NULL,
    [Id]                                   BIGINT             NOT NULL,
    [Name]                                 NVARCHAR (50)      NOT NULL,
    [RouteDefinitionId]                    BIGINT             NULL,
    [SegmentsDefinitionId]                 BIGINT             NULL,
    [PP_Id]                                INT                NULL,
    [PL_Id]                                INT                NOT NULL,
    [Prod_Id]                              INT                NOT NULL,
    [Status]                               INT                NOT NULL,
    [PlannedStartDate]                     DATETIMEOFFSET (7) NULL,
    [PlannedEndDate]                       DATETIMEOFFSET (7) NULL,
    [PlannedQuantity]                      INT                NOT NULL,
    [DiscreteVirtualUnitId]                INT                NOT NULL,
    [NumberOfIncompleteMaterialLotActuals] BIGINT             NOT NULL,
    [Priority]                             INT                DEFAULT ((0)) NOT NULL,
    [CancelledOn]                          DATETIMEOFFSET (7) NULL,
    [CompletedOn]                          DATETIMEOFFSET (7) NULL,
    [ReadyOn]                              DATETIMEOFFSET (7) NULL,
    [StartedOn]                            DATETIMEOFFSET (7) NULL,
    CONSTRAINT [PK_WorkOrders] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_WorkOrders_SegmentsDefinitions_SegmentsDefinitionId] FOREIGN KEY ([SegmentsDefinitionId]) REFERENCES [WorkOrder].[SegmentsDefinitions] ([Id])
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [IX_WorkOrders_Name]
    ON [WorkOrder].[WorkOrders]([Name] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_WorkOrders_SegmentsDefinitionId]
    ON [WorkOrder].[WorkOrders]([SegmentsDefinitionId] ASC);

