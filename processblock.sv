APP = poly1305FinalProject

all:
	@echo "Targets:"
	@echo "simprep          Build Verilator based system simulator"
	@echo "swprep           Compile software (Current application: $(APP))"
	@echo "runfst           Run Verilator and record waveformtrace"
	@echo "run              Run Verilator"
	@echo "syn              Prepare code for synthesis (to be done in ex-custom-obex-syn repo)"
	@echo "clean            Remove intermediate files"

build/custom_ibex_0/sim-verilator/Vtop_verilator:
	fusesoc --cores-root=. run --target=sim --tool=verilator --setup --build custom_ibex

simprep: build/custom_ibex_0/sim-verilator/Vtop_verilator

sw/c/build/demo/$(APP)/$(APP):
	mkdir -p sw/c/build
	cd sw/c/build; cmake ..; make

swprep: sw/c/build/demo/$(APP)/$(APP)

runfst: build/custom_ibex_0/sim-verilator/Vtop_verilator sw/c/build/demo/$(APP)/$(APP)
	build/custom_ibex_0/sim-verilator/Vtop_verilator -t sim.fst --meminit=ram,./sw/c/build/demo/$(APP)/$(APP)

run: build/custom_ibex_0/sim-verilator/Vtop_verilator sw/c/build/demo/$(APP)/$(APP)
	build/custom_ibex_0/sim-verilator/Vtop_verilator --meminit=ram,./sw/c/build/demo/$(APP)/$(APP)

syn:
	fusesoc --cores-root=. run --target=synth --tool=vivado --setup custom_ibex

clean:
	rm -rf build sw/c/build


#/opt/lowrisc-toolchain-rv32imcb-20240206-1/bin/riscv32-unknown-elf-gcc  
#-I/home/pschaumont/ex-custom-ibex/sw/c/common 
#-march=rv32imc 
#-mabi=ilp32 
#-mcmodel=medany 
#-Wall 
#-fvisibility=hidden 
#-ffreestanding 
#-g 
#-MD 
#-MT 
#demo/myreg-test/CMakeFiles/myreg-test.dir/main.c.obj 
#-MF CMakeFiles/myreg-test.dir/main.c.obj.d 
#-o CMakeFiles/myreg-test.dir/main.c.obj 
#-c /home/pschaumont/ex-custom-ibex/sw/c/demo/myreg-test/main.c
#
#
#/opt/lowrisc-toolchain-rv32imcb-20240206-1/bin/riscv32-unknown-elf-gcc 
#-march=rv32imc 
#-mabi=ilp32 
#-mcmodel=medany 
#-Wall 
#-fvisibility=hidden 
#-ffreestanding 
#-g 
#-nostartfiles 
#-T "/home/pschaumont/ex-custom-ibex/sw/c/../common/link.ld" 
#"CMakeFiles/myreg-test.dir/main.c.obj" 
#../../common/CMakeFiles/common.dir/demo_system.c.obj 
#../../common/CMakeFiles/common.dir/uart.c.obj 
#../../common/CMakeFiles/common.dir/timer.c.obj 
#../../common/CMakeFiles/common.dir/gpio.c.obj 
#../../common/CMakeFiles/common.dir/pwm.c.obj 
#../../common/CMakeFiles/common.dir/spi.c.obj 
#../../common/CMakeFiles/common.dir/crt0.S.obj 
#-o myreg-test
