module sensor ( 
	input clk, //El reloj de la FPGA es de 50M
	input Eco,
	input llenado,
	output valv,
	output led_llenado,
	output reg trig,
	output reg [6:0] display,
	output reg [7:0] anodos
	);
//Se generan los registros para cada variable necesaria del ultrasonico.
	reg [26:0] cont;
	reg [26:0] dist;
	reg valv_status;
// Se definen las condiciones iniciales. 
	initial
	begin
	cont = 0;
	trig = clk;
	dist = 0;
//Estas variables son para mostrar en los Displays el valor de la distancia en cm o %.
	cont_t = 0;
	cont_clk1 = 0;
	cont_anodos = 0;
	clk1 = 0;
//Se define que la valvula inicia encendida.
	valv_status = 1'b1;
	end
//Parte del calculo para el sensor ultrasonico.
	always @(posedge clk)
		begin
		cont = cont + 1;
		if (cont < 1024) //1024 corresponde a 10us para el Trigger
			trig =  1'b1;
		else
			begin
			trig = 1'b0;
			if (Eco == 1)
				begin
				cont_t = cont_t + 1; //Esto calcula el tiempo que se demora la señal en ir y volver al sensor
				dist = (cont_t*34/100_000); //Esta parte corresponde al calculo de la distancia = Velocidad*Tiempo/2
				end
			else if (Eco == 0)
				begin
				cont_t = 0;
				end
			end
		end
		
//Se definen los registros para las variables necesarias para los Displays.
	reg [26:0] cont_t;
	reg [13:0] cont_clk1;
	wire [6:0] display1;
	wire [6:0] display2;
	wire [6:0] display3;
	reg [1:0] cont_anodos;
	reg clk1;
	
//Divisor de frecuencia de 200us de periodo para que se pueda observar bien el valor en los Displays. 
	always @(posedge clk)
		begin
		if (cont_clk1 < 5_000)
			cont_clk1 = cont_clk1 + 13'b0000000000001;
		else
			begin
				clk1 =~ clk1;
				cont_clk1=0;
			end
		end
		
//Se llama a la función distt del modulo de displays.
	displays distt(clk,dist,display1,display2,display3);

//Multiplexor sincronizado por reloj
	always @(posedge clk1)
	begin 
	cont_anodos=cont_anodos+2'b01;
		case (cont_anodos)
			0 : begin anodos=8'b01111111; display=display1; end
			
			1 : begin anodos=8'b10111111; display=display2; end
			
			2 : begin anodos=8'b11011111; display=display3; end
		endcase
	end

//Condicionales para el encendido de la valvula
	assign valv = valv_status;
	assign led_llenado = ~llenado;
	
	always @(posedge clk1)
		begin
			if (dist <= 10)
				valv_status = 1'b0;
			else if (dist >= 17)
				valv_status = 1'b1;
			else
				valv_status = ~llenado;
		end
		
endmodule
