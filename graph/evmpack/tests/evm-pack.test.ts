import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { Address, BigInt } from "@graphprotocol/graph-ts"
import { AddMaintainer } from "../generated/schema"
import { AddMaintainer as AddMaintainerEvent } from "../generated/EVMPack/EVMPack"
import { handleAddMaintainer } from "../src/evm-pack"
import { createAddMaintainerEvent } from "./evm-pack-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/subgraphs/developing/creating/unit-testing-framework/#tests-structure

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let name = "Example string value"
    let maintainer = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let newAddMaintainerEvent = createAddMaintainerEvent(name, maintainer)
    handleAddMaintainer(newAddMaintainerEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/subgraphs/developing/creating/unit-testing-framework/#write-a-unit-test

  test("AddMaintainer created and stored", () => {
    assert.entityCount("AddMaintainer", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "AddMaintainer",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "name",
      "Example string value"
    )
    assert.fieldEquals(
      "AddMaintainer",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "maintainer",
      "0x0000000000000000000000000000000000000001"
    )

    // More assert options:
    // https://thegraph.com/docs/en/subgraphs/developing/creating/unit-testing-framework/#asserts
  })
})
