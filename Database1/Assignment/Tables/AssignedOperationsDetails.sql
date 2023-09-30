CREATE TABLE [Assignment].[AssignedOperationsDetails] (
    [id]                    BIGINT         IDENTITY (1, 1) NOT NULL,
    [assignedBy]            VARCHAR (100)  NOT NULL,
    [assignedOn]            DATETIME2 (7)  NULL,
    [assignedTo]            VARCHAR (100)  NOT NULL,
    [createdOn]             DATETIME2 (7)  NULL,
    [lastModifiedOn]        DATETIME2 (7)  NULL,
    [materialLotActualId]   BIGINT         NULL,
    [segmentDefinitionInfo] VARCHAR (4000) NULL,
    [segmentActualId]       BIGINT         NULL,
    [segmentId]             BIGINT         NOT NULL,
    [workOrderId]           BIGINT         NOT NULL,
    PRIMARY KEY CLUSTERED ([id] ASC)
);


GO
CREATE NONCLUSTERED INDEX [Ix_AssignedOperationsDetails]
    ON [Assignment].[AssignedOperationsDetails]([assignedTo] ASC, [workOrderId] ASC, [segmentId] ASC, [segmentActualId] ASC);

