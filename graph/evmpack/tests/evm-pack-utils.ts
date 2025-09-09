import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt } from "@graphprotocol/graph-ts"
import {
  AddMaintainer,
  Initialized,
  NewRelease,
  RegisterPackage,
  RemoveMaintainer,
  UpdatePackageMeta
} from "../generated/EVMPack/EVMPack"

export function createAddMaintainerEvent(
  name: string,
  maintainer: Address
): AddMaintainer {
  let addMaintainerEvent = changetype<AddMaintainer>(newMockEvent())

  addMaintainerEvent.parameters = new Array()

  addMaintainerEvent.parameters.push(
    new ethereum.EventParam("name", ethereum.Value.fromString(name))
  )
  addMaintainerEvent.parameters.push(
    new ethereum.EventParam(
      "maintainer",
      ethereum.Value.fromAddress(maintainer)
    )
  )

  return addMaintainerEvent
}

export function createInitializedEvent(version: BigInt): Initialized {
  let initializedEvent = changetype<Initialized>(newMockEvent())

  initializedEvent.parameters = new Array()

  initializedEvent.parameters.push(
    new ethereum.EventParam(
      "version",
      ethereum.Value.fromUnsignedBigInt(version)
    )
  )

  return initializedEvent
}

export function createNewReleaseEvent(
  name: string,
  version: string,
  manifest: string
): NewRelease {
  let newReleaseEvent = changetype<NewRelease>(newMockEvent())

  newReleaseEvent.parameters = new Array()

  newReleaseEvent.parameters.push(
    new ethereum.EventParam("name", ethereum.Value.fromString(name))
  )
  newReleaseEvent.parameters.push(
    new ethereum.EventParam("version", ethereum.Value.fromString(version))
  )
  newReleaseEvent.parameters.push(
    new ethereum.EventParam("manifest", ethereum.Value.fromString(manifest))
  )

  return newReleaseEvent
}

export function createRegisterPackageEvent(
  name: string,
  maintainer: Address,
  packageType: i32,
  meta: string
): RegisterPackage {
  let registerPackageEvent = changetype<RegisterPackage>(newMockEvent())

  registerPackageEvent.parameters = new Array()

  registerPackageEvent.parameters.push(
    new ethereum.EventParam("name", ethereum.Value.fromString(name))
  )
  registerPackageEvent.parameters.push(
    new ethereum.EventParam(
      "maintainer",
      ethereum.Value.fromAddress(maintainer)
    )
  )
  registerPackageEvent.parameters.push(
    new ethereum.EventParam(
      "packageType",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(packageType))
    )
  )
  registerPackageEvent.parameters.push(
    new ethereum.EventParam("meta", ethereum.Value.fromString(meta))
  )

  return registerPackageEvent
}

export function createRemoveMaintainerEvent(
  name: string,
  maintainer: Address
): RemoveMaintainer {
  let removeMaintainerEvent = changetype<RemoveMaintainer>(newMockEvent())

  removeMaintainerEvent.parameters = new Array()

  removeMaintainerEvent.parameters.push(
    new ethereum.EventParam("name", ethereum.Value.fromString(name))
  )
  removeMaintainerEvent.parameters.push(
    new ethereum.EventParam(
      "maintainer",
      ethereum.Value.fromAddress(maintainer)
    )
  )

  return removeMaintainerEvent
}

export function createUpdatePackageMetaEvent(
  name: string,
  meta: string
): UpdatePackageMeta {
  let updatePackageMetaEvent = changetype<UpdatePackageMeta>(newMockEvent())

  updatePackageMetaEvent.parameters = new Array()

  updatePackageMetaEvent.parameters.push(
    new ethereum.EventParam("name", ethereum.Value.fromString(name))
  )
  updatePackageMetaEvent.parameters.push(
    new ethereum.EventParam("meta", ethereum.Value.fromString(meta))
  )

  return updatePackageMetaEvent
}
