import {
  AddMaintainer as AddMaintainerEvent,
  Initialized as InitializedEvent,
  NewRelease as NewReleaseEvent,
  RegisterPackage as RegisterPackageEvent,
  RemoveMaintainer as RemoveMaintainerEvent,
  UpdatePackageMeta as UpdatePackageMetaEvent
} from "../generated/EVMPack/EVMPack"
import {
  AddMaintainer,
  Initialized,
  NewRelease,
  RegisterPackage,
  RemoveMaintainer,
  UpdatePackageMeta
} from "../generated/schema"

export function handleAddMaintainer(event: AddMaintainerEvent): void {
  let entity = new AddMaintainer(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.name = event.params.name
  entity.maintainer = event.params.maintainer

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleInitialized(event: InitializedEvent): void {
  let entity = new Initialized(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.version = event.params.version

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleNewRelease(event: NewReleaseEvent): void {
  let entity = new NewRelease(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.name = event.params.name
  entity.version = event.params.version
  entity.manifest = event.params.manifest

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleRegisterPackage(event: RegisterPackageEvent): void {
  let entity = new RegisterPackage(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.name = event.params.name
  entity.maintainer = event.params.maintainer
  entity.packageType = event.params.packageType
  entity.meta = event.params.meta

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleRemoveMaintainer(event: RemoveMaintainerEvent): void {
  let entity = new RemoveMaintainer(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.name = event.params.name
  entity.maintainer = event.params.maintainer

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}

export function handleUpdatePackageMeta(event: UpdatePackageMetaEvent): void {
  let entity = new UpdatePackageMeta(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  )
  entity.name = event.params.name
  entity.meta = event.params.meta

  entity.blockNumber = event.block.number
  entity.blockTimestamp = event.block.timestamp
  entity.transactionHash = event.transaction.hash

  entity.save()
}
